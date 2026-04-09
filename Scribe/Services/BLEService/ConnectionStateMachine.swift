import Foundation
import Combine

/// State machine managing ConnectionState transitions with reconnection logic
public final class ConnectionStateMachine {
    
    // MARK: - State Publisher
    public var statePublisher: AnyPublisher<ConnectionState, Never> {
        stateSubject.eraseToAnyPublisher()
    }
    
    // MARK: - Private Properties
    private let stateSubject: CurrentValueSubject<ConnectionState, Never>
    private var currentState: ConnectionState {
        return stateSubject.value
    }
    
    private var reconnectAttempts = 0
    private let maxReconnectAttempts = 5
    
    // MARK: - Initialization
    public init(initialState: ConnectionState = .disconnected) {
        self.stateSubject = CurrentValueSubject(initialState)
    }
    
    // MARK: - State Transitions
    
    /// Transition to connecting state
    public func startConnecting() {
        transition(to: .connecting)
    }
    
    /// Transition to connected state
    public func markConnected() {
        reconnectAttempts = 0
        transition(to: .connected)
    }
    
    /// Transition to binding state
    public func startBinding() {
        transition(to: .binding)
    }
    
    /// Transition to initializing state
    public func startInitializing() {
        transition(to: .initializing)
    }
    
    /// Transition to initialized state
    public func markInitialized() {
        transition(to: .initialized)
    }
    
    /// Transition to bound state
    public func markBound() {
        transition(to: .bound)
    }
    
    /// Transition to failed state with error
    public func fail(with error: String) {
        transition(to: .failed(error))
    }
    
    /// Attempt reconnection, returns true if should retry
    public func attemptReconnection() -> Bool {
        reconnectAttempts += 1
        if reconnectAttempts <= maxReconnectAttempts {
            transition(to: .reconnecting(reconnectAttempts))
            return true
        }
        return false
    }
    
    /// Reset to disconnected state
    public func reset() {
        reconnectAttempts = 0
        transition(to: .disconnected)
    }
    
    // MARK: - Private Methods
    
    private func transition(to newState: ConnectionState) {
        let oldState = currentState
        stateSubject.send(newState)
        ScribeLogger.debug("State transition: \(oldState) -> \(newState)", category: .ble)
    }
}
