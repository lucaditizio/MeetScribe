import Foundation

/// Protocol: Presenter → View (display updates)
public protocol RecordingListViewInput: AnyObject {
    func displayRecordings(_ recordings: [Recording])
    func displayError(_ error: Error)
}
