import Foundation

/// Configuration for the ML inference pipeline
public struct PipelineConfig: Sendable {
    // MARK: - Model URLs
    let swissGermanWhisperURL = "jlnslv/whisper-large-v3-turbo-swiss-german-coreml"
    
    // MARK: - Diarization
    let diarizationClusteringThreshold: Double = 0.35
    let minSpeakers: Int = 1
    let maxSpeakers: Int = 8
    
    // MARK: - LLM Configuration
    let singlePassThreshold: Int = 25_000
    let chunkSize: Int = 12_000
    let chunkOverlap: Int = 1_200
    let llmModelFileName = "Llama-3.2-3B-Instruct-Q4_K_M.gguf"
    let llmModelDownloadURL = "https://huggingface.co/bartowski/Llama-3.2-3B-Instruct-GGUF/resolve/main/Llama-3.2-3B-Instruct-Q4_K_M.gguf"
    
    // MARK: - Pipeline Timing
    let stageTimeout: TimeInterval = 60
    
    // MARK: - ASR Configuration
    let minASRSamples: Int = 8000  // 0.5 sec at 16kHz
}
