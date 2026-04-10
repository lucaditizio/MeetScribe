import Foundation

/// Protocol: External → Module (configuration)
public protocol RecordingListModuleInput: AnyObject {
    func configureWith(delegate: RecordingListModuleOutput?)
}
