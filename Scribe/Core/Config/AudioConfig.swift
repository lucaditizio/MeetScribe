import Foundation

/// Audio configuration for unified Opus format
struct AudioConfig: Sendable {
    // MARK: - Unified Format (Opus/CAF)
    let sampleRate: Double = 16_000
    let channelCount: Int = 1
    let frameSize: Int = 320  // 20ms at 16kHz
    let fileExtension = "caf"
    let formatHint = "opus"
    
    // MARK: - Internal Mic Fallback
    let internalMicSampleRate: Double = 48_000
    let internalMicFormat = "m4a"  // fallback for internal mic AAC
}
