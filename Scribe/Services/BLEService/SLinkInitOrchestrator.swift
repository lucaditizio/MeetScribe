import Foundation
import Combine

/// Orchestrates the 8-step SLink initialization sequence with timeout handling
public final class SLinkInitOrchestrator {
    
    // MARK: - Properties
    private let stateMachine: ConnectionStateMachine
    private let commandDelay: TimeInterval
    private let stepTimeout: TimeInterval
    private var cancellables = Set<AnyCancellable>()
    private var currentStep = 0
    private var timeoutTimer: Timer?
    private var sendCommand: ((SLinkCommand) -> Void)?
    
    // MARK: - Initialization
    public init(
        stateMachine: ConnectionStateMachine,
        commandDelay: TimeInterval = 0.1,
        stepTimeout: TimeInterval = 5.0
    ) {
        self.stateMachine = stateMachine
        self.commandDelay = commandDelay
        self.stepTimeout = stepTimeout
    }
    
    // MARK: - Public Methods
    
    /// Start the 8-step SLink initialization sequence
    public func startInitialization(sendCommand: @escaping (SLinkCommand) -> Void) {
        currentStep = 0
        self.sendCommand = sendCommand
        stateMachine.startBinding()
        
        // Execute first step
        executeStep(0)
    }
    
    /// Handle response from device
    public func handleResponse(_ response: SLinkPacket) -> Bool {
        // Cancel timeout timer
        timeoutTimer?.invalidate()
        
        // Check if response matches expected command for current step
        guard isValidResponse(response) else {
            ScribeLogger.error("Unexpected response: \(response.command)", category: .ble)
            stateMachine.fail(with: "Invalid response at step \(currentStep)")
            return false
        }
        
        currentStep += 1
        
        // Check if initialization complete
        if currentStep >= 8 {
            stateMachine.markInitialized()
            ScribeLogger.info("SLink initialization complete", category: .ble)
            return true
        }
        
        // Execute next step
        executeStep(currentStep)
        return false
    }
    
    /// Reset the orchestrator
    public func reset() {
        currentStep = 0
        timeoutTimer?.invalidate()
        timeoutTimer = nil
        cancellables.removeAll()
        sendCommand = nil
    }
    
    // MARK: - Private Methods
    
    private func executeStep(_ step: Int) {
        guard step < 8 else { return }
        
        let command = commandForStep(step)
        
        // Update state machine
        updateStateForStep(step)
        
        // Send command after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + commandDelay) { [weak self] in
            guard let self = self else { return }
            self.sendCommand?(command)
            ScribeLogger.debug("Sent SLink command: \(command)", category: .ble)
            
            // Start timeout timer for this step
            self.startTimeoutTimer()
        }
    }
    
    private func startTimeoutTimer() {
        timeoutTimer?.invalidate()
        timeoutTimer = Timer.scheduledTimer(withTimeInterval: stepTimeout, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            ScribeLogger.error("Step \(self.currentStep) timed out after \(self.stepTimeout)s", category: .ble)
            self.stateMachine.fail(with: "Step \(self.currentStep) timeout")
        }
    }
    
    private func commandForStep(_ step: Int) -> SLinkCommand {
        switch step {
        case 0: return .handshake
        case 1: return .sendSerial
        case 2: return .getDeviceInfo
        case 3: return .configure
        case 4: return .statusControl
        case 5: return .command18
        case 6: return .command0A
        case 7: return .command17
        default: return .handshake
        }
    }
    
    private func updateStateForStep(_ step: Int) {
        switch step {
        case 0: stateMachine.startBinding()
        case 1, 2, 3, 4, 5, 6, 7: stateMachine.startInitializing()
        default: break
        }
    }
    
    private func isValidResponse(_ response: SLinkPacket) -> Bool {
        let expectedCommand = commandForStep(currentStep)
        return response.command == expectedCommand.rawValue
    }
}
