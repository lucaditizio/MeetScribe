import Foundation

public struct WaveformPlaybackState: Equatable {
    public var isPlaying: Bool
    public var currentTime: TimeInterval
    public var duration: TimeInterval
    public var speed: Float
    public var waveformBars: [Float]
    
    public init(
        isPlaying: Bool = false,
        currentTime: TimeInterval = 0,
        duration: TimeInterval = 0,
        speed: Float = 1.0,
        waveformBars: [Float] = []
    ) {
        self.isPlaying = isPlaying
        self.currentTime = currentTime
        self.duration = duration
        self.speed = speed
        self.waveformBars = waveformBars
    }
}
