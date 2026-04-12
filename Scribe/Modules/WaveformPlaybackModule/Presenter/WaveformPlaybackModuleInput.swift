import Foundation

public protocol WaveformPlaybackModuleInput: AnyObject {
    func configureWith(recordingId: String)
}
