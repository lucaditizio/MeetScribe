import Foundation

public protocol RecordingDetailViewInput: AnyObject {
    func displayRecording(_ recording: Recording)
    func displayError(_ error: Error)
}
