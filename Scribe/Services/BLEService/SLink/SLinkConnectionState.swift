import Foundation

/// Connection states for SLink initialization sequence
public enum SLinkConnectionState: Equatable {
    case disconnected
    case connecting
    case handshaking
    case sendingSerial
    case gettingDeviceInfo
    case configuring
    case statusControl
    case initializing
    case initialized
    case bound
    case syncing
    case recording
    case failed(String)
    
    public var isError: Bool {
        if case .failed = self { return true }
        return false
    }
}
