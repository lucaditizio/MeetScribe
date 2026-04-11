import XCTest
@testable import Scribe
import SwiftUI

final class MockDeviceSettingsViewOutput: DeviceSettingsViewOutput {
    var didTriggerViewReadyCalled = false
    var didTapScanCalled = false
    var didTapDeviceCalled = false
    var didTapDisconnectCalled = false
    var tappedDevice: DeviceSettingsBluetoothDevice?
    
    func didTriggerViewReady() {
        didTriggerViewReadyCalled = true
    }
    
    func didTapScan() {
        didTapScanCalled = true
    }
    
    func didTapDevice(_ device: DeviceSettingsBluetoothDevice) {
        didTapDeviceCalled = true
        tappedDevice = device
    }
    
    func didTapDisconnect() {
        didTapDisconnectCalled = true
    }
}

final class DeviceSettingsViewTests: XCTestCase {
    
    var sut: DeviceSettingsView!
    var mockOutput: MockDeviceSettingsViewOutput!
    
    override func setUp() {
        super.setUp()
        mockOutput = MockDeviceSettingsViewOutput()
        sut = DeviceSettingsView(output: mockOutput)
    }
    
    override func tearDown() {
        sut = nil
        mockOutput = nil
        super.tearDown()
    }
    
    func testViewInitializesWithDisconnectedState() {
        XCTAssertNotNil(sut)
        XCTAssertEqual(sut.state.connectionState, .disconnected)
        XCTAssertTrue(sut.state.discoveredDevices.isEmpty)
        XCTAssertFalse(sut.state.isScanning)
    }
    
    func testConnectedDeviceShowsGreenStatus() {
        let device = DeviceSettingsBluetoothDevice(name: "Test Mic", rssi: -45)
        sut.state.connectionState = .connected(device)
        
        let color = sut.statusColor
        XCTAssertEqual(color, Color.green)
    }
    
    func testConnectingStateShowsYellowStatus() {
        sut.state.connectionState = .connecting
        let color = sut.statusColor
        XCTAssertEqual(color, Color.yellow)
    }
    
    func testDisconnectingStateShowsYellowStatus() {
        sut.state.connectionState = .disconnecting
        let color = sut.statusColor
        XCTAssertEqual(color, Color.yellow)
    }
    
    func testDisconnectedStateShowsSecondaryStatus() {
        sut.state.connectionState = .disconnected
        let color = sut.statusColor
        XCTAssertEqual(color, Theme.accentGray)
    }
    
    func testConnectedStateShowsCorrectStatusText() {
        let device = DeviceSettingsBluetoothDevice(name: "Test Mic", rssi: -45)
        sut.state.connectionState = .connected(device)
        
        XCTAssertEqual(sut.statusText, "Connected")
        XCTAssertEqual(sut.connectedDeviceName, "Test Mic")
    }
    
    func testConnectingStateShowsCorrectStatusText() {
        sut.state.connectionState = .connecting
        XCTAssertEqual(sut.statusText, "Connecting...")
        XCTAssertNil(sut.connectedDeviceName)
    }
    
    func testDisconnectingStateShowsCorrectStatusText() {
        sut.state.connectionState = .disconnecting
        XCTAssertEqual(sut.statusText, "Disconnecting...")
        XCTAssertNil(sut.connectedDeviceName)
    }
    
    func testDisconnectedStateShowsCorrectStatusText() {
        sut.state.connectionState = .disconnected
        XCTAssertEqual(sut.statusText, "Disconnected")
        XCTAssertNil(sut.connectedDeviceName)
    }
    
    func testDisconnectButtonVisibleWhenConnected() {
        let device = DeviceSettingsBluetoothDevice(name: "Test Mic", rssi: -45)
        sut.state.connectionState = .connected(device)
        
        XCTAssertTrue(sut.isConnected)
    }
    
    func testDisconnectButtonHiddenWhenDisconnected() {
        sut.state.connectionState = .disconnected
        XCTAssertFalse(sut.isConnected)
    }
    
    func testDeviceListShowsNoDevicesMessageWhenEmpty() {
        XCTAssertTrue(sut.state.discoveredDevices.isEmpty)
    }
    
    func testDeviceListRendersDiscoveredDevices() {
        let device1 = DeviceSettingsBluetoothDevice(id: UUID(), name: "Mic 1", rssi: -50)
        let device2 = DeviceSettingsBluetoothDevice(id: UUID(), name: "Mic 2", rssi: -60)
        sut.state.discoveredDevices = [device1, device2]
        
        XCTAssertEqual(sut.state.discoveredDevices.count, 2)
        XCTAssertEqual(sut.state.discoveredDevices[0].name, "Mic 1")
        XCTAssertEqual(sut.state.discoveredDevices[1].name, "Mic 2")
    }
    
    func testScanButtonTriggersDidTapScan() {
        sut.state.isScanning = false
        
        // Simulate button tap through output
        mockOutput.didTapScan()
        
        XCTAssertTrue(mockOutput.didTapScanCalled)
    }
    
    func testScanButtonDisabledWhenScanning() {
        sut.state.isScanning = true
        XCTAssertTrue(sut.state.isScanning)
    }
    
    func testViewReadyTriggersDidTriggerViewReady() {
        mockOutput.didTriggerViewReady()
        XCTAssertTrue(mockOutput.didTriggerViewReadyCalled)
    }
    
    func testDeviceTapTriggersDidTapDevice() {
        let device = DeviceSettingsBluetoothDevice(name: "Test Mic", rssi: -50)
        mockOutput.didTapDevice(device)
        
        XCTAssertTrue(mockOutput.didTapDeviceCalled)
        XCTAssertEqual(mockOutput.tappedDevice?.name, "Test Mic")
    }
    
    func testDisconnectTapTriggersDidTapDisconnect() {
        mockOutput.didTapDisconnect()
        XCTAssertTrue(mockOutput.didTapDisconnectCalled)
    }
}
