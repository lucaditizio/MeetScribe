import Foundation
public protocol DeviceSettingsInteractorOutput: AnyObject {
    func didDiscoverDevices(_ devices: [DeviceSettingsBluetoothDevice])
    func didUpdateConnectionState(_ state: DeviceSettingsConnectionState)
    func didFailWithError(_ error: Error)
}
