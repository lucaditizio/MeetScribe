import Foundation

public enum ProcessingStage: String, Equatable {
    case initializing = "Initializing"
    case vad = "Voice Detection"
    case languageDetection = "Language Detection"
    case asr = "Transcription"
    case diarization = "Speaker Identification"
    case summarization = "Generating Summary"
    case complete = "Complete"
}

public struct AgentGeneratingState {
    public var currentStage: ProcessingStage
    public var progress: Double
    public var isProcessing: Bool
    public var error: Error?
    
    public init(
        currentStage: ProcessingStage = .initializing,
        progress: Double = 0,
        isProcessing: Bool = false,
        error: Error? = nil
    ) {
        self.currentStage = currentStage
        self.progress = progress
        self.isProcessing = isProcessing
        self.error = error
    }
}
