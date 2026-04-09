import Foundation
import Combine

/// Sends periodic keepalive commands every 3 seconds
public final class KeepAliveService {
    
    // MARK: - Properties
    private var timer: Timer?
    private let interval: TimeInterval
    private let sendCommand: () -> Void
    
    // MARK: - Initialization
    public init(interval: TimeInterval = 3.0, sendCommand: @escaping () -> Void) {
        self.interval = interval
        self.sendCommand = sendCommand
    }
    
    // MARK: - Public Methods
    
    /// Start sending keepalive commands
    public func start() {
        stop() // Ensure no duplicate timers
        
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.sendKeepAlive()
        }
        
        ScribeLogger.info("Keepalive service started", category: .ble)
    }
    
    /// Stop sending keepalive commands
    public func stop() {
        timer?.invalidate()
        timer = nil
        ScribeLogger.info("Keepalive service stopped", category: .ble)
    }
    
    // MARK: - Private Methods
    
    private func sendKeepAlive() {
        sendCommand()
        ScribeLogger.debug("Sent keepalive", category: .ble)
    }
}
