import Foundation

public protocol RecordingDetailInteractorOutput: AnyObject {
    func didObtainRecording(_ recording: Recording)
    func didFailWithError(_ error: Error)
}
