import Foundation
public protocol DeviceSettingsViewOutput: AnyObject {
    func didTriggerViewReady()
    func didTapScan()
    func didTapDevice(_ device: DeviceSettingsBluetoothDevice)
    func didTapDisconnect()
}
