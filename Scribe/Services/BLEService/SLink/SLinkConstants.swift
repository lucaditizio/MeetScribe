import Foundation

/// Constants for SLink BLE protocol
public enum SLinkConstants {
    /// Command delay between SLink init steps (seconds)
    public static let commandDelay: TimeInterval = 0.1
    
    /// SLink packet header bytes
    public static let headerBytes: [UInt8] = [0x80, 0x08]
}
