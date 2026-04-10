import Foundation

public protocol RecordingDetailInteractorInput: AnyObject {
    func obtainRecording(id: String)
    func updateRecording(_ recording: Recording)
}
