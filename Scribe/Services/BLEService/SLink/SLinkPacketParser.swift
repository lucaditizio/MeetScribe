import Foundation

/// Stateful parser for SLink packets from byte stream
public final class SLinkPacketParser {
    private var buffer: [UInt8] = []
    
    public init() {}
    
    /// Feed bytes into parser and return any complete packets
    public func feed(_ data: Data) -> [SLinkPacket] {
        buffer.append(contentsOf: data)
        var packets: [SLinkPacket] = []
        
        while let packet = tryParsePacket() {
            packets.append(packet)
        }
        
        return packets
    }
    
    /// Attempt to parse a single packet from buffer
    private func tryParsePacket() -> SLinkPacket? {
        // Find header [0x80, 0x08]
        guard let headerIndex = findHeader() else {
            return nil
        }
        
        // Need at least header (2) + command (2) + length (2) = 6 bytes
        guard buffer.count >= headerIndex + 6 else {
            return nil
        }
        
        // Parse command and length
        let command = UInt16(buffer[headerIndex + 2]) << 8 | UInt16(buffer[headerIndex + 3])
        let length = UInt16(buffer[headerIndex + 4]) << 8 | UInt16(buffer[headerIndex + 5])
        
        // Check if we have full packet
        let totalLength = 6 + Int(length) + 2  // header + cmd/len + payload + checksum
        guard buffer.count >= headerIndex + totalLength else {
            return nil
        }
        
        // Extract payload
        let payloadStart = headerIndex + 6
        let payload = Array(buffer[payloadStart..<payloadStart + Int(length)])
        
        // Verify checksum
        let checksum = UInt16(buffer[headerIndex + totalLength - 2]) << 8 | UInt16(buffer[headerIndex + totalLength - 1])
        let expectedChecksum = SLinkChecksum.calculate(command: command, payload: payload)
        
        guard checksum == expectedChecksum else {
            // Invalid checksum, remove header and continue
            buffer.removeSubrange(0..<headerIndex + 2)
            return nil
        }
        
        // Remove parsed bytes from buffer
        buffer.removeSubrange(0..<headerIndex + totalLength)
        
        return SLinkPacket(command: command, payload: payload)
    }
    
    /// Find header bytes [0x80, 0x08] in buffer
    private func findHeader() -> Int? {
        // Need at least 2 bytes to search for header
        guard buffer.count >= 2 else {
            return nil
        }
        
        for i in 0..<(buffer.count - 1) {
            if buffer[i] == 0x80 && buffer[i + 1] == 0x08 {
                return i
            }
        }
        return nil
    }
}
