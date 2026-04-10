import Foundation

public protocol RecordingDetailModuleInput: AnyObject {
    func configureWith(recordingId: String)
}
