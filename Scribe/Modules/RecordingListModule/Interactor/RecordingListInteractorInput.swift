import Foundation

/// Protocol: Presenter → Interactor (business logic)
public protocol RecordingListInteractorInput: AnyObject {
    func obtainRecordings()
    func deleteRecording(id: String)
    func startRecording()
    func stopRecording()
}
