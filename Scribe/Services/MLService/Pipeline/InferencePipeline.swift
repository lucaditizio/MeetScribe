import Foundation
import Combine
import AVFoundation

public final class InferencePipeline: InferencePipelineProtocol {
    
    private let vadService: VADServiceProtocol
    private let languageDetector: LanguageDetectionProtocol
    private let transcriptionService: TranscriptionServiceProtocol
    private let fallbackTranscriptionService: TranscriptionServiceProtocol
    private let diarizationService: DiarizationServiceProtocol
    private let summarizationService: SummarizationServiceProtocol
    private let progressTracker: ProgressTracker
    private let progressSubject = PassthroughSubject<InferenceProgress, Never>()
    private let config: PipelineConfig
    private var isCancelled = false
    
    private let audioConverter = AudioConverter()
    
    public init(
        vadService: VADServiceProtocol,
        languageDetector: LanguageDetectionProtocol,
        transcriptionService: TranscriptionServiceProtocol,
        fallbackTranscriptionService: TranscriptionServiceProtocol,
        diarizationService: DiarizationServiceProtocol,
        summarizationService: SummarizationServiceProtocol
    ) {
        self.vadService = vadService
        self.languageDetector = languageDetector
        self.transcriptionService = transcriptionService
        self.fallbackTranscriptionService = fallbackTranscriptionService
        self.diarizationService = diarizationService
        self.summarizationService = summarizationService
        self.progressTracker = ProgressTracker()
        self.config = PipelineConfig()
        ScribeLogger.info("InferencePipeline initialized", category: .ml)
    }
    
    public var progressPublisher: AnyPublisher<InferenceProgress, Never> {
        progressSubject.eraseToAnyPublisher()
    }
    
    public func process(recording: Recording) async throws -> (Transcript, MeetingSummary) {
        ScribeLogger.info("Starting pipeline processing for recording: \(recording.id)", category: .ml)
        
        guard !isCancelled else {
            ScribeLogger.error("Pipeline cancelled before start", category: .ml)
            throw PipelineError.cancelled
        }
        
        let fileURL = getFileURL(for: recording)
        let audioData = try await loadAudioData(from: recording, fileURL: fileURL)
        
        _ = try await runStageVAD(audioURL: fileURL)
        
        let languageConfidence = try await runStageLanguageDetection(audioData: audioData)
        
        let isSwissGerman = languageConfidence.isSwissGerman
        
        let transcriptionText = try await runStageASR(
            audioData: audioData,
            language: languageConfidence.language,
            useSwissGermanModel: isSwissGerman
        )
        
        _ = try await runStageDiarization(audioData: audioData)
        
        let summary = try await runStageSummarization(transcriptText: transcriptionText)
        
        let transcript = Transcript(
            recordingId: recording.id,
            fullText: transcriptionText,
            detectedLanguage: languageConfidence.language
        )
        
        ScribeLogger.info("Pipeline completed successfully", category: .ml)
        
        return (transcript, summary)
    }
    
    public func cancel() {
        ScribeLogger.info("Pipeline cancellation requested", category: .ml)
        isCancelled = true
    }
    
    private func runStageVAD(audioURL: URL) async throws -> [VADSegment] {
        ScribeLogger.info("Stage 1/5: Voice Detection started", category: .ml)
        progressTracker.updateProgress(stage: "Voice Detection", progress: 0.0)
        progressSubject.send(InferenceProgress(stage: "Voice Detection", progress: progressTracker.globalProgress))
        
        try checkCancellation()
        
        // Let VADService handle manager initialization and processing internally
        let hasSpeech = try await vadService.hasSpeech(audioURL: audioURL)
        
        progressTracker.updateProgress(stage: "Voice Detection", progress: 1.0)
        progressSubject.send(InferenceProgress(stage: "Voice Detection", progress: progressTracker.globalProgress))
        ScribeLogger.info("Stage 1/5: Voice Detection completed, speech detected: \(hasSpeech)", category: .ml)
        
        if !hasSpeech {
            throw PipelineError.noSpeechDetected
        }
        
        return [VADSegment(startTime: 0, endTime: 0, isVoiceActive: true)]
    }
    
    private func runStageLanguageDetection(audioData: Data) async throws -> LanguageConfidence {
        ScribeLogger.info("Stage 2/5: Language Detection started", category: .ml)
        progressTracker.updateProgress(stage: "Language Detection", progress: 0.0)
        progressSubject.send(InferenceProgress(stage: "Language Detection", progress: progressTracker.globalProgress))
        
        try checkCancellation()
        
        let languageConfidence = try await languageDetector.detectLanguage(from: audioData)
        
        progressTracker.updateProgress(stage: "Language Detection", progress: 1.0)
        progressSubject.send(InferenceProgress(stage: "Language Detection", progress: progressTracker.globalProgress))
        ScribeLogger.info(
            "Stage 2/5: Language Detection completed, language: \(languageConfidence.language)",
            category: .ml
        )
        
        return languageConfidence
    }
    
    private func runStageASR(audioData: Data, language: String, useSwissGermanModel: Bool) async throws -> String {
        ScribeLogger.info("Stage 3/5: Transcription started", category: .ml)
        progressTracker.updateProgress(stage: "Transcription", progress: 0.0)
        progressSubject.send(InferenceProgress(stage: "Transcription", progress: progressTracker.globalProgress))
        
        try checkCancellation()
        
        let asrServiceToUse = useSwissGermanModel ? transcriptionService : fallbackTranscriptionService
        ScribeLogger.info("Using \(useSwissGermanModel ? "Swiss German" : "Fallback") ASR model", category: .ml)
        
        let transcription = try await asrServiceToUse.transcribe(
            audioData: audioData,
            language: language
        )
        
        progressTracker.updateProgress(stage: "Transcription", progress: 1.0)
        progressSubject.send(InferenceProgress(stage: "Transcription", progress: progressTracker.globalProgress))
        ScribeLogger.info("Stage 3/5: Transcription completed", category: .ml)
        
        return transcription
    }
    
    private func runStageDiarization(audioData: Data) async throws -> [SpeakerSegment] {
        ScribeLogger.info("Stage 4/5: Speaker Identification started", category: .ml)
        progressTracker.updateProgress(stage: "Speaker Identification", progress: 0.0)
        progressSubject.send(InferenceProgress(stage: "Speaker Identification", progress: progressTracker.globalProgress))
        
        try checkCancellation()
        
        let segments = try await diarizationService.diarize(
            audioData: audioData,
            maxSpeakers: config.maxSpeakers
        )
        
        progressTracker.updateProgress(stage: "Speaker Identification", progress: 1.0)
        progressSubject.send(InferenceProgress(stage: "Speaker Identification", progress: progressTracker.globalProgress))
        ScribeLogger.info("Stage 4/5: Speaker Identification completed with \(segments.count) segments", category: .ml)
        
        return segments
    }
    
    private func runStageSummarization(transcriptText: String) async throws -> MeetingSummary {
        ScribeLogger.info("Stage 5/5: Generating Summary started", category: .ml)
        progressTracker.updateProgress(stage: "Generating Summary", progress: 0.0)
        progressSubject.send(InferenceProgress(stage: "Generating Summary", progress: progressTracker.globalProgress))
        
        try checkCancellation()
        
        let summary = try await summarizationService.summarize(text: transcriptText)
        
        progressTracker.updateProgress(stage: "Generating Summary", progress: 1.0)
        progressSubject.send(InferenceProgress(stage: "Generating Summary", progress: progressTracker.globalProgress))
        ScribeLogger.info("Stage 5/5: Generating Summary completed", category: .ml)
        
        return summary
    }
    
    private func getFileURL(for recording: Recording) -> URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsPath.appendingPathComponent(recording.fileName)
    }

    private func loadAudioData(from recording: Recording, fileURL: URL) async throws -> Data {
        
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            ScribeLogger.error("Audio file not found: \(fileURL.path)", category: .ml)
            throw PipelineError.invalidAudioData
        }
        
        do {
            let floatSamples = try await audioConverter.convertCAFToPCMForASR(url: fileURL)
            
            var data = Data()
            floatSamples.withUnsafeBufferPointer { bufferPointer in
                guard let baseAddress = bufferPointer.baseAddress else { return }
                data.append(UnsafeBufferPointer(start: baseAddress, count: floatSamples.count))
            }
            
            ScribeLogger.debug("Loaded and converted \(data.count) bytes (\(floatSamples.count) Float32 samples) from audio file", category: .ml)
            return data
        } catch {
            ScribeLogger.error("Failed to load audio file: \(error.localizedDescription)", category: .ml)
            throw PipelineError.invalidAudioData
        }
    }
    
    private func checkCancellation() throws {
        if isCancelled {
            throw PipelineError.cancelled
        }
    }
}

struct VADSegment {
    let startTime: Double
    let endTime: Double
    let isVoiceActive: Bool
}

enum PipelineError: LocalizedError {
    case cancelled
    case noSpeechDetected
    case invalidAudioData
    case stageTimeout(String)
    case stageFailed(String, Error)
    
    var errorDescription: String? {
        switch self {
        case .cancelled:
            return "Pipeline was cancelled"
        case .noSpeechDetected:
            return "No speech detected in audio"
        case .invalidAudioData:
            return "Invalid audio data format"
        case .stageTimeout(let stage):
            return "Timeout during \(stage) stage"
        case .stageFailed(let stage, let error):
            return "\(stage) stage failed: \(error.localizedDescription)"
        }
    }
}