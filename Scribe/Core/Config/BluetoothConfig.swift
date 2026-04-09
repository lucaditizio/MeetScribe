import Foundation

/// Bluetooth LE configuration for SLink protocol
struct BluetoothConfig: Sendable {
    // MARK: - UUIDs
    let serviceUUID = "E49A3001-F69A-11E8-8EB2-F2801F1B9FD1"
    let audioCharacteristicUUID = "E49A3003-F69A-11E8-8EB2-F2801F1B9FD1"
    let commandCharacteristicUUID = "F0F1"
    let fileTransferCharacteristicUUID = "F0F2"
    let fileTransferChar2UUID = "F0F3"
    let fileTransferChar3UUID = "F0F4"
    let batteryServiceUUID = "180F"
    let batteryCharacteristicUUID = "2A19"
    
    // MARK: - SLink Protocol
    let deviceSerial = "129950"
    let connectionTimeout: TimeInterval = 10
    let sLinkTimeout: TimeInterval = 5
    let keepAliveInterval: TimeInterval = 3
    
    // MARK: - Device Filtering
    let rssiThreshold: Int = -70
    let maxReconnectAttempts: Int = 5
    let knownDeviceNames = [
        "LA518", "LA519", "L027", "L813", "L814", "L815", 
        "L816", "L817", "MAR-2518", "19CAEEngine_2MicPhone", "MlpAES2MicTV"
    ]
}
