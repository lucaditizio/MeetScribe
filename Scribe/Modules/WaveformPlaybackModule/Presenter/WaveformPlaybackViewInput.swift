import Foundation

public protocol WaveformPlaybackViewInput: AnyObject {
    func displayWaveform(_ bars: [Float])
    func displayPlaybackState(isPlaying: Bool, currentTime: TimeInterval, duration: TimeInterval, speed: Float)
    func displayError(_ error: Error)
}
