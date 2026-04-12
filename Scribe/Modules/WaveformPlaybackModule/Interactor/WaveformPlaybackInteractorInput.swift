import Foundation

public protocol WaveformPlaybackInteractorInput: AnyObject {
    func configureWith(recordingId: String)
    func obtainWaveformData()
    func playAudio()
    func pauseAudio()
    func seekTo(_ time: TimeInterval)
    func cycleSpeed()
}
