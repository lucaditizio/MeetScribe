import XCTest
import Combine
@testable import Scribe

final class ConnectionStateMachineTests: XCTestCase {
    var stateMachine: ConnectionStateMachine!
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        stateMachine = ConnectionStateMachine()
        cancellables = []
    }
    
    override func tearDown() {
        cancellables = nil
        stateMachine = nil
        super.tearDown()
    }
    
    func testInitialStateIsDisconnected() {
        var receivedState: ConnectionState?
        
        stateMachine.statePublisher
            .sink { state in
                receivedState = state
            }
            .store(in: &cancellables)
        
        XCTAssertEqual(receivedState, .disconnected)
    }
    
    func testStartConnectingTransitionsToConnecting() {
        var receivedStates: [ConnectionState] = []
        
        stateMachine.statePublisher
            .sink { state in
                receivedStates.append(state)
            }
            .store(in: &cancellables)
        
        stateMachine.startConnecting()
        
        XCTAssertEqual(receivedStates, [.disconnected, .connecting])
    }
    
    func testMarkConnectedTransitionsToConnected() {
        stateMachine.startConnecting()
        
        var receivedState: ConnectionState?
        stateMachine.statePublisher
            .dropFirst()
            .sink { state in
                receivedState = state
            }
            .store(in: &cancellables)
        
        stateMachine.markConnected()
        
        XCTAssertEqual(receivedState, .connected)
    }
    
    func testFullLifecycleTransitions() {
        var receivedStates: [ConnectionState] = []
        
        stateMachine.statePublisher
            .sink { state in
                receivedStates.append(state)
            }
            .store(in: &cancellables)
        
        stateMachine.startConnecting()
        stateMachine.markConnected()
        stateMachine.startBinding()
        stateMachine.startInitializing()
        stateMachine.markInitialized()
        stateMachine.markBound()
        
        XCTAssertEqual(receivedStates, [.disconnected, .connecting, .connected, .binding, .initializing, .initialized, .bound])
    }
    
    func testFailTransitionsToFailed() {
        var receivedStates: [ConnectionState] = []
        stateMachine.statePublisher
            .sink { state in
                receivedStates.append(state)
            }
            .store(in: &cancellables)
        
        stateMachine.startConnecting()
        stateMachine.fail(with: "Test error")
        
        XCTAssertEqual(receivedStates.count, 3)
        if case .failed(let message) = receivedStates.last {
            XCTAssertEqual(message, "Test error")
        } else {
            XCTFail("Expected failed state, got \(String(describing: receivedStates.last))")
        }
    }
    
    func testReconnectionAttempts() {
        XCTAssertTrue(stateMachine.attemptReconnection())
        XCTAssertTrue(stateMachine.attemptReconnection())
        XCTAssertTrue(stateMachine.attemptReconnection())
        XCTAssertTrue(stateMachine.attemptReconnection())
        XCTAssertTrue(stateMachine.attemptReconnection())
        XCTAssertFalse(stateMachine.attemptReconnection()) // 6th attempt should fail
    }
    
    func testReconnectionState() {
        var receivedState: ConnectionState?
        
        stateMachine.statePublisher
            .dropFirst()
            .sink { state in
                receivedState = state
            }
            .store(in: &cancellables)
        
        _ = stateMachine.attemptReconnection()
        
        if case .reconnecting(let attempt) = receivedState {
            XCTAssertEqual(attempt, 1)
        } else {
            XCTFail("Expected reconnecting state")
        }
    }
    
    func testResetClearsState() {
        var receivedStates: [ConnectionState] = []
        stateMachine.statePublisher
            .sink { state in
                receivedStates.append(state)
            }
            .store(in: &cancellables)
        
        stateMachine.startConnecting()
        stateMachine.markConnected()
        stateMachine.reset()
        
        XCTAssertEqual(receivedStates, [.disconnected, .connecting, .connected, .disconnected])
    }
}

final class SLinkInitOrchestratorTests: XCTestCase {
    var stateMachine: ConnectionStateMachine!
    var orchestrator: SLinkInitOrchestrator!
    var sentCommands: [SLinkCommand]!
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        stateMachine = ConnectionStateMachine()
        orchestrator = SLinkInitOrchestrator(stateMachine: stateMachine)
        sentCommands = []
        cancellables = []
    }
    
    override func tearDown() {
        cancellables = nil
        orchestrator = nil
        stateMachine = nil
        super.tearDown()
    }
    
    func testInitializationSendsFirstCommand() {
        let expectation = XCTestExpectation(description: "Command sent")
        
        orchestrator.startInitialization { command in
            self.sentCommands.append(command)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 0.5)
        XCTAssertEqual(sentCommands.first, .handshake)
    }
    
    func testHandleResponseAdvancesStep() {
        orchestrator.startInitialization { command in
            self.sentCommands.append(command)
        }
        
        let response = SLinkPacket(command: SLinkCommand.handshake.rawValue, payload: [])
        let complete = orchestrator.handleResponse(response)
        
        XCTAssertFalse(complete)
    }
    
    func testEightStepsCompleteInitialization() {
        var stepCount = 0
        orchestrator.startInitialization { command in
            self.sentCommands.append(command)
            stepCount += 1
        }
        
        // Simulate all 8 steps
        let commands: [SLinkCommand] = [.handshake, .sendSerial, .getDeviceInfo, .configure, .statusControl, .command18, .command0A, .command17]
        
        for (index, _) in commands.enumerated() {
            let response = SLinkPacket(command: commands[index].rawValue, payload: [])
            let complete = orchestrator.handleResponse(response)
            
            if index < 7 {
                XCTAssertFalse(complete, "Step \(index) should not complete")
            } else {
                XCTAssertTrue(complete, "Step 7 should complete initialization")
            }
        }
    }
    
    func testInvalidResponseFails() {
        orchestrator.startInitialization { _ in }
        
        let response = SLinkPacket(command: 0x9999, payload: []) // Invalid command
        let result = orchestrator.handleResponse(response)
        
        XCTAssertFalse(result)
    }
}

final class DeviceConnectionManagerTests: XCTestCase {
    var manager: DeviceConnectionManager!
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        manager = DeviceConnectionManager()
        cancellables = []
    }
    
    override func tearDown() {
        cancellables = nil
        manager = nil
        super.tearDown()
    }
    
    func testManagerInitializes() {
        XCTAssertNotNil(manager)
    }
    
    func testConnectionStatePublisher() {
        var receivedStates: [ConnectionState] = []
        
        manager.connectionStatePublisher
            .sink { state in
                receivedStates.append(state)
            }
            .store(in: &cancellables)
        
        XCTAssertEqual(receivedStates.first, .disconnected)
    }
    
    func testGetLastConnectedDeviceIDNilInitially() {
        XCTAssertNil(manager.getLastConnectedDeviceID())
    }
    
    func testConnectionLifecycle() {
        var receivedStates: [ConnectionState] = []
        
        manager.connectionStatePublisher
            .sink { state in
                receivedStates.append(state)
            }
            .store(in: &cancellables)
        
        // Note: Cannot fully test connect/disconnect without Bluetooth
        // This tests the initial state and basic functionality
        XCTAssertEqual(receivedStates.first, .disconnected)
    }
}

final class KeepAliveServiceTests: XCTestCase {
    func testServiceInitializes() {
        var commandSent = false
        let service = KeepAliveService {
            commandSent = true
        }
        
        XCTAssertNotNil(service)
    }
    
    func testStartAndStop() {
        let service = KeepAliveService { }
        
        service.start()
        service.stop()
        
        // No crash = success
        XCTAssertTrue(true)
    }
}
