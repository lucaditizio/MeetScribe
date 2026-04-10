import Foundation
import WhisperKit

/// Whisper CoreML-based transcription service for Swiss German speech recognition
/// Implements sequential memory management: load → transcribe → nullify
public final class WhisperCoreMLService: TranscriptionServiceProtocol {
    
    // MARK: - Properties
    
    private var whisperKit: WhisperKit?
    private let config: PipelineConfig
    private let logger: ScribeLogger
    
    // MARK: - Initialization
    
    init(config: PipelineConfig = PipelineConfig(), logger: ScribeLogger = .shared) {
        self.config = config
        self.logger = logger
    }
    
    // MARK: - TranscriptionServiceProtocol
    
    public func transcribe(audioData: Data, language: String?) async throws -> String {
        logger.debug("Starting transcription", category: .ml)
        
        guard !audioData.isEmpty else {
            throw WhisperError.emptyAudioData
        }
        
        guard audioData.count >= config.minASRSamples else {
            throw WhisperError.insufficientSamples
        }
        
        // Convert Data to Float32 array
        let floatSamples = try convertToFloat32Array(from: audioData)
        
        // Perform transcription with sequential memory management
        let transcription = try await performTranscription(
            audioSamples: floatSamples,
            language: language
        )
        
        logger.info("Transcription completed: \(transcription.prefix(100))...", category: .ml)
        
        return transcription
    }
    
    // MARK: - Private Methods
    
    private func performTranscription(audioSamples: [Float], language: String?) async throws -> String {
        // Step 1: Load model
        try await loadModel()
        
        // Step 2: Run transcription
        let transcription: String
        
        do {
            transcription = try await runTranscription(
                audioSamples: audioSamples,
                language: language
            )
        } catch {
            // Ensure model is nullified even if transcription fails
            nullifyModel()
            throw error
        }
        
        // Step 3: Nullify model (CRITICAL for memory management)
        nullifyModel()
        
        return transcription
    }
    
    private func loadModel() async throws {
        logger.info("Loading Swiss German Whisper CoreML model", category: .ml)
        
        guard whisperKit == nil else {
            logger.debug("Whisper model already loaded", category: .ml)
            return
        }
        
        do {
            let whisperConfig = WhisperKitConfig(
                model: "large-v3-turbo",
                modelRepo: config.swissGermanWhisperURL,
                download: true
            )
            
            whisperKit = try await WhisperKit(whisperConfig)
            
            logger.info("Whisper model loaded successfully", category: .ml)
        } catch {
            logger.error("Failed to load Whisper model: \(error.localizedDescription)", category: .ml)
            throw WhisperError.modelLoadFailed(error.localizedDescription)
        }
    }
    
    private func runTranscription(audioSamples: [Float], language: String?) async throws -> String {
        guard let whisperKit = whisperKit else {
            throw WhisperError.modelNotLoaded
        }
        
        logger.debug("Running transcription on \(audioSamples.count) samples", category: .ml)
        
        do {
            let decodingOptions = DecodingOptions(
                task: .transcribe,
                language: language ?? "gsw",
                temperature: 0.0,
                wordTimestamps: false
            )
            
            let result = try await whisperKit.transcribe(
                audioArray: audioSamples,
                decodeOptions: decodingOptions
            )
            
            guard let transcriptionText = result.first?.text.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) else {
                logger.warning("No transcription result returned", category: .ml)
                return ""
            }
            
            logger.debug("Transcription produced \(transcriptionText.count) characters", category: .ml)
            
            return transcriptionText
        } catch {
            logger.error("Transcription failed: \(error.localizedDescription)", category: .ml)
            throw WhisperError.transcriptionFailed(error.localizedDescription)
        }
    }
    
    private func nullifyModel() {
        whisperKit = nil
        logger.debug("Whisper model nullified for memory management", category: .ml)
    }
    
    // MARK: - Audio Conversion
    
    private func convertToFloat32Array(from audioData: Data) throws -> [Float] {
        guard audioData.count % 4 == 0 else {
            throw WhisperError.invalidAudioFormat
        }
        
        let sampleCount = audioData.count / 4
        var samples: [Float] = []
        samples.reserveCapacity(sampleCount)
        
        audioData.withUnsafeBytes { pointer in
            guard let baseAddress = pointer.baseAddress else { return }
            let floatPointer = baseAddress.bindMemory(to: Float.self, capacity: sampleCount)
            
            for i in 0..<sampleCount {
                samples.append(floatPointer[i])
            }
        }
        
        logger.debug("Converted \(sampleCount) Float32 samples", category: .ml)
        
        return samples
    }
}

// MARK: - WhisperKit Compute Options

private struct WhisperKitComputeOptions {
    let preferredDevice: String? = nil
    let useFallback: Bool = true
}

// MARK: - Whisper Errors

enum WhisperError: LocalizedError {
    case emptyAudioData
    case insufficientSamples
    case invalidAudioFormat
    case modelNotLoaded
    case modelLoadFailed(String)
    case transcriptionFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .emptyAudioData:
            return "Audio data is empty"
        case .insufficientSamples:
            return "Audio data has insufficient samples for transcription"
        case .invalidAudioFormat:
            return "Audio data format is invalid (expected Float32 PCM)"
        case .modelNotLoaded:
            return "Whisper model is not loaded"
        case .modelLoadFailed(let reason):
            return "Failed to load Whisper model: \(reason)"
        case .transcriptionFailed(let reason):
            return "Transcription failed: \(reason)"
        }
    }
}