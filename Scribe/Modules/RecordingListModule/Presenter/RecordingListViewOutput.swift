import Foundation

/// Protocol: View → Presenter (user actions)
public protocol RecordingListViewOutput: AnyObject {
    func didTriggerViewReady()
    func didTapRecord()
    func didTapRecording(id: String)
    func didTapSettings()
    func didDeleteRecording(id: String)
}
