import Foundation
import Combine

public final class InferencePipeline: InferencePipelineProtocol {
    
    private let vadService: VADServiceProtocol
    private let languageDetector: LanguageDetectionProtocol
    private let transcriptionService: TranscriptionServiceProtocol
    private let diarizationService: DiarizationServiceProtocol
    private let summarizationService: SummarizationServiceProtocol
    private let progressTracker: ProgressTracker
    private let progressSubject = PassthroughSubject<InferenceProgress, Never>()
    private let config: PipelineConfig
    private var isCancelled = false
    
    public init(
        vadService: VADServiceProtocol,
        languageDetector: LanguageDetectionProtocol,
        transcriptionService: TranscriptionServiceProtocol,
        diarizationService: DiarizationServiceProtocol,
        summarizationService: SummarizationServiceProtocol
    ) {
        self.vadService = vadService
        self.languageDetector = languageDetector
        self.transcriptionService = transcriptionService
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
        
        let audioData = try loadAudioData(from: recording)
        
        _ = try await runStageVAD(audioData: audioData)
        
        let languageConfidence = try await runStageLanguageDetection(audioData: audioData)
        
        let transcriptionText = try await runStageASR(
            audioData: audioData,
            language: languageConfidence.language
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
    
    private func runStageVAD(audioData: Data) async throws -> [VADSegment] {
        ScribeLogger.info("Stage 1/5: VAD started", category: .ml)
        progressTracker.updateProgress(stage: "VAD", progress: 0.0)
        progressSubject.send(InferenceProgress(stage: "VAD", progress: 0.0))
        
        try checkCancellation()
        
        let hasSpeech = vadService.process(buffer: audioData)
        
        progressTracker.updateProgress(stage: "VAD", progress: 1.0)
        progressSubject.send(InferenceProgress(stage: "VAD", progress: 1.0))
        ScribeLogger.info("Stage 1/5: VAD completed, speech detected: \(hasSpeech)", category: .ml)
        
        if !hasSpeech {
            throw PipelineError.noSpeechDetected
        }
        
        return [VADSegment(startTime: 0, endTime: 0, isVoiceActive: true)]
    }
    
    private func runStageLanguageDetection(audioData: Data) async throws -> LanguageConfidence {
        ScribeLogger.info("Stage 2/5: Language Detection started", category: .ml)
        progressTracker.updateProgress(stage: "Language Detection", progress: 0.0)
        progressSubject.send(InferenceProgress(stage: "Language Detection", progress: 0.0))
        
        try checkCancellation()
        
        let languageConfidence = try await languageDetector.detectLanguage(from: audioData)
        
        progressTracker.updateProgress(stage: "Language Detection", progress: 1.0)
        progressSubject.send(InferenceProgress(stage: "Language Detection", progress: 1.0))
        ScribeLogger.info(
            "Stage 2/5: Language Detection completed, language: \(languageConfidence.language)",
            category: .ml
        )
        
        return languageConfidence
    }
    
    private func runStageASR(audioData: Data, language: String) async throws -> String {
        ScribeLogger.info("Stage 3/5: ASR started", category: .ml)
        progressTracker.updateProgress(stage: "ASR", progress: 0.0)
        progressSubject.send(InferenceProgress(stage: "ASR", progress: 0.0))
        
        try checkCancellation()
        
        let transcription = try await transcriptionService.transcribe(
            audioData: audioData,
            language: language
        )
        
        progressTracker.updateProgress(stage: "ASR", progress: 1.0)
        progressSubject.send(InferenceProgress(stage: "ASR", progress: 1.0))
        ScribeLogger.info("Stage 3/5: ASR completed", category: .ml)
        
        return transcription
    }
    
    private func runStageDiarization(audioData: Data) async throws -> [SpeakerSegment] {
        ScribeLogger.info("Stage 4/5: Diarization started", category: .ml)
        progressTracker.updateProgress(stage: "Diarization", progress: 0.0)
        progressSubject.send(InferenceProgress(stage: "Diarization", progress: 0.0))
        
        try checkCancellation()
        
        let segments = try await diarizationService.diarize(
            audioData: audioData,
            maxSpeakers: config.maxSpeakers
        )
        
        progressTracker.updateProgress(stage: "Diarization", progress: 1.0)
        progressSubject.send(InferenceProgress(stage: "Diarization", progress: 1.0))
        ScribeLogger.info("Stage 4/5: Diarization completed with \(segments.count) segments", category: .ml)
        
        return segments
    }
    
    private func runStageSummarization(transcriptText: String) async throws -> MeetingSummary {
        ScribeLogger.info("Stage 5/5: Summarization started", category: .ml)
        progressTracker.updateProgress(stage: "Summarization", progress: 0.0)
        progressSubject.send(InferenceProgress(stage: "Summarization", progress: 0.0))
        
        try checkCancellation()
        
        let summary = try await summarizationService.summarize(text: transcriptText)
        
        progressTracker.updateProgress(stage: "Summarization", progress: 1.0)
        progressSubject.send(InferenceProgress(stage: "Summarization", progress: 1.0))
        ScribeLogger.info("Stage 5/5: Summarization completed", category: .ml)
        
        return summary
    }
    
    private func loadAudioData(from recording: Recording) throws -> Data {
        let fileURL = URL(fileURLWithPath: recording.filePath)
        
        guard FileManager.default.fileExists(atPath: recording.filePath) else {
            ScribeLogger.error("Audio file not found: \(recording.filePath)", category: .ml)
            throw PipelineError.invalidAudioData
        }
        
        do {
            let data = try Data(contentsOf: fileURL)
            ScribeLogger.debug("Loaded \(data.count) bytes from audio file", category: .ml)
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