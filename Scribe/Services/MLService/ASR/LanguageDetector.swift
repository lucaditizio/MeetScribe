import Foundation

/// Language detection implementation using Whisper's built-in language detection
public final class LanguageDetector: LanguageDetectionProtocol {
    private let config: PipelineConfig
    private let logger: ScribeLogger
    private let whisperService: TranscriptionServiceProtocol
    
    public init(config: PipelineConfig, whisperService: TranscriptionServiceProtocol, logger: ScribeLogger = .shared) {
        self.config = config
        self.whisperService = whisperService
        self.logger = logger
    }
    
    public func detectLanguage(from audioData: Data) async throws -> LanguageConfidence {
        logger.debug("Starting language detection", category: .ml)
        
        guard !audioData.isEmpty else {
            throw LanguageDetectionError.emptyAudioData
        }
        
        guard audioData.count >= config.minASRSamples else {
            throw LanguageDetectionError.insufficientSamples
        }
        
        // Leverage WhisperCoreMLService to perform true inference
        var detectedLanguage = try await whisperService.detectLanguage(audioData: audioData)
        let confidence: Double = 0.95 // WhisperKit doesn't easily expose segment confidence outside of transcription right now
        
        // Anti-Hallucination Guard: Flurin17 degrades to "en" on short clips lacking context anchors
        let sampleCount = audioData.count / 4
        let durationSeconds = Double(sampleCount) / 16000.0
        
        if durationSeconds < 12.0 && detectedLanguage == "en" {
            logger.warning("Short clip (\(String(format: "%.1f", durationSeconds))s) hallucinated as 'en'. Overriding to 'gsw'.", category: .ml)
            detectedLanguage = "gsw"
        }
        
        logger.info("Language detected: \(detectedLanguage) with confidence \(confidence)", category: .ml)
        
        let isSwissGerman = checkForSwissGerman(language: detectedLanguage, confidence: confidence)
        
        return LanguageConfidence(
            language: detectedLanguage,
            confidence: confidence,
            isSwissGerman: isSwissGerman
        )
    }
    
    private func checkForSwissGerman(language: String, confidence: Double) -> Bool {
        let swissGermanCodes = ["gsw", "de-CH", "swiss_german"]
        
        if swissGermanCodes.contains(language.lowercased()) {
            logger.debug("Detected Swiss German language", category: .ml)
            return true
        }
        
        // Additional check: high confidence on German with specific patterns
        if language.lowercased() == "de" && confidence > 0.9 {
            logger.debug("High confidence German - potential Swiss German", category: .ml)
            return true
        }
        
        return false
    }
}

// MARK: - Language Detection Errors

enum LanguageDetectionError: LocalizedError {
    case emptyAudioData
    case insufficientSamples
    case whisperModelNotLoaded
    case detectionFailed
    
    var errorDescription: String? {
        switch self {
        case .emptyAudioData:
            return "Audio data is empty"
        case .insufficientSamples:
            return "Audio data has insufficient samples for detection"
        case .whisperModelNotLoaded:
            return "Whisper model not loaded"
        case .detectionFailed:
            return "Language detection failed"
        }
    }
}
