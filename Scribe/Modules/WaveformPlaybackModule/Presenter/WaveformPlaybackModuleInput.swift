import Foundation

public protocol WaveformPlaybackModuleInput: AnyObject {
    func configureWith(audioURL: URL)
}
