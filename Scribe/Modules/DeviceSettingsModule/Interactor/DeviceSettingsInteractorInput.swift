import Foundation
public protocol DeviceSettingsInteractorInput: AnyObject {
    func startScan()
    func connectToDevice(_ device: DeviceSettingsBluetoothDevice)
    func disconnect()
}
