import Foundation
import CoreBluetooth

/// Represents a discovered BLE device
public struct BluetoothDevice: Identifiable, Equatable, Sendable {
    public let id: String  // CBPeripheral identifier UUID string
    public let name: String
    public let rssi: Int
    public let isConnected: Bool
    public let batteryLevel: Int?
    
    public init(
        id: String,
        name: String,
        rssi: Int,
        isConnected: Bool = false,
        batteryLevel: Int? = nil
    ) {
        self.id = id
        self.name = name
        self.rssi = rssi
        self.isConnected = isConnected
        self.batteryLevel = batteryLevel
    }
    
    public static func == (lhs: BluetoothDevice, rhs: BluetoothDevice) -> Bool {
        lhs.id == rhs.id
    }
}

/// Delegate protocol for scanner connection events
public protocol ScannerConnectionDelegate: AnyObject {
    func scannerDidConnect(_ device: BluetoothDevice)
    func scannerDidFailToConnect(_ device: BluetoothDevice, error: Error?)
    func scannerDidDisconnect(_ device: BluetoothDevice, error: Error?)
}
