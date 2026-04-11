import Foundation

public protocol WaveformPlaybackInteractorOutput: AnyObject {
    func didObtainWaveformData(_ bars: [Float])
    func didUpdatePlaybackState(isPlaying: Bool, currentTime: TimeInterval)
    func didFailWithError(_ error: Error)
}
