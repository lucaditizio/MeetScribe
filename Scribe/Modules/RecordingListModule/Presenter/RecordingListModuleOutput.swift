import Foundation

/// Protocol: Module → External (results)
public protocol RecordingListModuleOutput: AnyObject {
    func didSelectRecording(id: String)
}
