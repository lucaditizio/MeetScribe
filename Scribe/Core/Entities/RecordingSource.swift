import Foundation

/// Source of the recording audio
public enum RecordingSource: String, Codable, Sendable {
    case rawInternal = "internal"
    case rawBle = "ble"
}
