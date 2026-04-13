import Foundation
import FluidAudio

/// Fallback ASR service using FluidAudio Parakeet (.v3 -> parakeet-tdt-0.6b-v3-coreml)
/// Implements sequential memory management: load → transcribe → nullify
public final class FallbackASRService: TranscriptionServiceProtocol {
    
    // MARK: - Properties
    private var asrManager: AsrManager?
    private let config: PipelineConfig
    private let logger: ScribeLogger
    
    // MARK: - Initialization
    init(config: PipelineConfig = PipelineConfig(), logger: ScribeLogger = .shared) {
        self.config = config
        self.logger = logger
    }
    
    // MARK: - TranscriptionServiceProtocol
    
    public func transcribe(audioData: Data, language: String?) async throws -> String {
        logger.debug("Starting fallback transcription with Parakeet", category: .ml)
        
        guard !audioData.isEmpty else {
            throw FallbackError.emptyAudioData
        }
        
        guard audioData.count >= config.minASRSamples else {
            throw FallbackError.insufficientSamples
        }
        
        // Convert Data to Float32 array using our custom method
        let floatSamples = try convertToFloat32Array(from: audioData)
        
        // Step 1: Load model
        try await loadModel()
        
        guard let manager = asrManager else {
            throw FallbackError.modelNotLoaded
        }
        
        // Step 2: Run transcription
        var state = try TdtDecoderState()
        let resultText: String
        
        do {
            logger.debug("Running Parakeet fallback transcription on \(floatSamples.count) samples", category: .ml)
            let result = try await manager.transcribe(floatSamples, decoderState: &state)
            resultText = result.text.trimmingCharacters(in: .whitespacesAndNewlines)
            logger.info("Fallback transcription completed: \(resultText.prefix(100))...", category: .ml)
        } catch {
            nullifyModel()
            logger.error("Fallback transcription failed: \(error.localizedDescription)", category: .ml)
            throw FallbackError.transcriptionFailed(error.localizedDescription)
        }
        
        // Step 3: Nullify model (CRITICAL for memory management)
        nullifyModel()
        
        return resultText
    }

    public func detectLanguage(audioData: Data) async throws -> String {
        logger.debug("Starting fallback language detection with Parakeet (stubbed to 'en')", category: .ml)
        // Parakeet doesn't inherently expose language probabilities like Whisper since it outputs text directly.
        // We will default to English since this fallback routing handles everything except Swiss German.
        return "en"
    }
    
    // MARK: - Private Methods
    
    private func loadModel() async throws {
        logger.info("Loading Parakeet .v3 model for fallback", category: .ml)
        
        guard asrManager == nil else {
            logger.debug("Fallback Parakeet model already loaded", category: .ml)
            return
        }
        
        do {
            let models = try await AsrModels.downloadAndLoad(version: .v3)
            let manager = AsrManager()
            try await manager.loadModels(models)
            
            asrManager = manager
            logger.info("Fallback Parakeet model loaded successfully", category: .ml)
        } catch {
            logger.error("Failed to load fallback Parakeet model: \(error.localizedDescription)", category: .ml)
            throw FallbackError.modelLoadFailed(error.localizedDescription)
        }
    }
    
    private func nullifyModel() {
        if asrManager != nil {
            Task {
                await asrManager?.cleanup()
                asrManager = nil
                logger.debug("Fallback Parakeet model nullified and cleaned up for memory management", category: .ml)
            }
        }
    }
    
    // MARK: - Audio Conversion
    
    private func convertToFloat32Array(from audioData: Data) throws -> [Float] {
        guard audioData.count % 4 == 0 else {
            throw FallbackError.invalidAudioFormat
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
        
        logger.debug("Converted \(sampleCount) Float32 samples for fallback", category: .ml)
        
        return samples
    }
}

// MARK: - Fallback Errors

enum FallbackError: LocalizedError {
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
            return "Audio data has insufficient samples for fallback transcription"
        case .invalidAudioFormat:
            return "Audio data format is invalid (expected Float32 PCM)"
        case .modelNotLoaded:
            return "Fallback Parakeet model is not loaded"
        case .modelLoadFailed(let reason):
            return "Failed to load fallback Parakeet model: \(reason)"
        case .transcriptionFailed(let reason):
            return "Fallback transcription failed: \(reason)"
        }
    }
}
