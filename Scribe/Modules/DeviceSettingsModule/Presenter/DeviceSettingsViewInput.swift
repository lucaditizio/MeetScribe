import Foundation
public protocol DeviceSettingsViewInput: AnyObject {
    func displayDevices(_ devices: [DeviceSettingsBluetoothDevice])
    func displayConnectionState(_ state: DeviceSettingsConnectionState)
    func displayError(_ error: Error)
}
