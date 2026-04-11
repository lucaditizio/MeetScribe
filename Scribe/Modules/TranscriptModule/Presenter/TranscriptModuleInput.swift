import Foundation

public protocol TranscriptModuleInput: AnyObject {
    func configureWith(recordingId: String)
}
