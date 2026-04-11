import Foundation

public protocol WaveformPlaybackViewOutput: AnyObject {
    func didTriggerViewReady()
    func didTapPlayPause()
    func didTapSkipForward()
    func didTapSkipBackward()
    func didSeek(to time: TimeInterval)
    func didTapSpeed()
}
