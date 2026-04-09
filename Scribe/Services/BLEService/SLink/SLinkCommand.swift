import Foundation

/// SLink protocol commands for device initialization
public enum SLinkCommand: UInt16 {
    case handshake = 0x0202
    case sendSerial = 0x0203
    case getDeviceInfo = 0x0201
    case configure = 0x0204
    case statusControl = 0x0205
    case command18 = 0x0218
    case command0A = 0x020A
    case command17 = 0x0217
    
    /// Default payload for each command
    public var defaultPayload: [UInt8] {
        switch self {
        case .handshake:
            return []
        case .sendSerial:
            // "129950" padded to 17 bytes
            let serial = "129950"
            let padding = 17 - serial.count
            return Array(serial.utf8) + Array(repeating: 0x00, count: padding)
        case .getDeviceInfo:
            return []
        case .configure:
            return [0x1A, 0x04, 0x04, 0x0E, 0x29, 0x32]
        case .statusControl:
            return []
        case .command18:
            return [0x01]
        case .command0A:
            return []
        case .command17:
            return [0x00]
        }
    }
}
