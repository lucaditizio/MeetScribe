import Foundation

/// Represents a SLink protocol packet
public struct SLinkPacket {
    public let header: [UInt8]  // [0x80, 0x08]
    public let command: UInt16
    public let length: UInt16
    public let payload: [UInt8]
    public let checksum: UInt16
    
    public init(command: UInt16, payload: [UInt8] = []) {
        self.header = SLinkConstants.headerBytes
        self.command = command
        self.payload = payload
        self.length = UInt16(payload.count)
        self.checksum = SLinkChecksum.calculate(command: command, payload: payload)
    }
    
    /// Serialize packet to bytes
    public func serialize() -> Data {
        var bytes = header
        bytes.append(contentsOf: withUnsafeBytes(of: command.bigEndian, Array.init))
        bytes.append(contentsOf: withUnsafeBytes(of: length.bigEndian, Array.init))
        bytes.append(contentsOf: payload)
        bytes.append(contentsOf: withUnsafeBytes(of: checksum.bigEndian, Array.init))
        return Data(bytes)
    }
}

/// Calculate SLink checksum (XOR 0x5F00 mask)
public enum SLinkChecksum {
    public static func calculate(command: UInt16, payload: [UInt8]) -> UInt16 {
        var checksum: UInt16 = 0
        
        // XOR command bytes
        let commandBytes = withUnsafeBytes(of: command.bigEndian, Array.init)
        checksum ^= UInt16(commandBytes[0]) << 8 | UInt16(commandBytes[1])
        
        // XOR length bytes
        let length = UInt16(payload.count)
        let lengthBytes = withUnsafeBytes(of: length.bigEndian, Array.init)
        checksum ^= UInt16(lengthBytes[0]) << 8 | UInt16(lengthBytes[1])
        
        // XOR all payload bytes
        for byte in payload {
            checksum ^= UInt16(byte) << 8
        }
        
        // Apply 0x5F00 mask
        checksum ^= 0x5F00
        
        return checksum
    }
}
