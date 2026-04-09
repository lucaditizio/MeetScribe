import Foundation

/// Source of the recording audio
public enum RecordingSource: String, Codable, Sendable {
    case internalMic = "internal_mic"
    case bleMicrophone = "ble_microphone"
}
