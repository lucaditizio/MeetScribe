import Foundation

public struct DeviceSettingsBluetoothDevice: Equatable, Identifiable {
    public var id: UUID
    public var name: String
    public var rssi: Int
    
    public init(id: UUID = UUID(), name: String, rssi: Int) {
        self.id = id
        self.name = name
        self.rssi = rssi
    }
}

public enum DeviceSettingsConnectionState: Equatable {
    case disconnected
    case connecting
    case connected(DeviceSettingsBluetoothDevice)
    case disconnecting
}

public struct DeviceSettingsState: Equatable {
    public var discoveredDevices: [DeviceSettingsBluetoothDevice]
    public var connectionState: DeviceSettingsConnectionState
    public var isScanning: Bool
    
    public init(
        discoveredDevices: [DeviceSettingsBluetoothDevice] = [],
        connectionState: DeviceSettingsConnectionState = .disconnected,
        isScanning: Bool = false
    ) {
        self.discoveredDevices = discoveredDevices
        self.connectionState = connectionState
        self.isScanning = isScanning
    }
}
