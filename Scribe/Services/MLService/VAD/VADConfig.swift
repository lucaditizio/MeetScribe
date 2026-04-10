import Foundation

/// Configuration for Voice Activity Detection
public struct VADConfig: Sendable {
    public let threshold: Float
    public let windowSize: Int
    public let sampleRate: Double
    
    public init(
        threshold: Float = 0.5,
        windowSize: Int = 320,  // 20ms at 16kHz
        sampleRate: Double = 16000
    ) {
        self.threshold = threshold
        self.windowSize = windowSize
        self.sampleRate = sampleRate
    }
}
