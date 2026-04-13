import Foundation

/// Protocol: Presenter → Router (navigation)
public protocol RecordingListRouterInput: AnyObject {
    func openRecordingDetail(with recording: Recording)
    func openDeviceSettings()

}
