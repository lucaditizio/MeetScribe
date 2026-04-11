import XCTest
@testable import Scribe
import Combine

final class DeviceSettingsInteractorTests: XCTestCase {
    private var interactor: DeviceSettingsInteractor!
    private var mockOutput: MockDeviceSettingsInteractorOutput!
    private var mockScanner: MockBluetoothDeviceScannerForDeviceSettings!
    private var mockConnectionManager: MockDeviceConnectionManagerForDeviceSettings!
    
    override func setUp() {
        super.setUp()
        mockOutput = MockDeviceSettingsInteractorOutput()
        mockScanner = MockBluetoothDeviceScannerForDeviceSettings()
        mockConnectionManager = MockDeviceConnectionManagerForDeviceSettings()
        interactor = DeviceSettingsInteractor(
            scanner: mockScanner,
            connectionManager: mockConnectionManager
        )
    }
    
    override func tearDown() {
        interactor = nil
        mockOutput = nil
        mockScanner = nil
        mockConnectionManager = nil
        super.tearDown()
    }
    
    func testStartScanCallsScannerStartScan() {
        interactor.startScan()
        XCTAssertTrue(mockScanner.startScanCalled)
    }
    
    func testConnectToDeviceCallsConnectionManagerConnect() {
        let device = DeviceSettingsBluetoothDevice(
            id: UUID(),
            name: "Test Device",
            rssi: -60
        )
        interactor.connectToDevice(device)
        XCTAssertTrue(mockConnectionManager.connectCalled)
        XCTAssertEqual(mockConnectionManager.lastDevice?.name, "Test Device")
    }
    
    func testDisconnectCallsConnectionManagerDisconnect() {
        interactor.disconnect()
        XCTAssertTrue(mockConnectionManager.disconnectCalled)
    }
    
    func testDidDiscoverDevicesCallsOutputDidDiscoverDevices() async {
        let bluetoothDevices = [
            BluetoothDevice(id: "1", name: "Device 1", rssi: -50),
            BluetoothDevice(id: "2", name: "Device 2", rssi: -60)
        ]
        mockScanner.mockDeviceDiscovery(bluetoothDevices)
        await Task.yield()
        XCTAssertEqual(mockOutput.discoveredDevices.count, 2)
        XCTAssertEqual(mockOutput.discoveredDevices[0].name, "Device 1")
    }
    
    func testDidUpdateConnectionStateCallsOutputDidUpdateConnectionState() async {
        mockConnectionManager.mockSetConnectionState(.disconnected)
        await Task.yield()
        XCTAssertEqual(mockOutput.connectionState, .disconnected)
    }
    
    func testConnectionFailedCallsOutputDidFailWithError() async {
        let errorMessage = "Connection failed due to timeout"
        mockConnectionManager.mockSetConnectionState(.failed(errorMessage))
        await Task.yield()
        XCTAssertNotNil(mockOutput.error)
        XCTAssertEqual(mockOutput.error?.localizedDescription, errorMessage)
    }
}

// MARK: - Mocks

private final class MockBluetoothDeviceScannerForDeviceSettings: BluetoothDeviceScannerProtocol {
    var startScanCalled = false
    var stopScanCalled = false
    var lastDevice: BluetoothDevice?
    
    var devicesPublisher: AnyPublisher<[BluetoothDevice], Never> {
        devicesSubject.eraseToAnyPublisher()
    }
    var isScanningPublisher: AnyPublisher<Bool, Never> {
        isScanningSubject.eraseToAnyPublisher()
    }
    
    private let devicesSubject = CurrentValueSubject<[BluetoothDevice], Never>([])
    private let isScanningSubject = CurrentValueSubject<Bool, Never>(false)
    
    func startScan() {
        startScanCalled = true
        isScanningSubject.send(true)
    }
    
    func stopScan() {
        stopScanCalled = true
        isScanningSubject.send(false)
    }
    
    func mockDeviceDiscovery(_ devices: [BluetoothDevice]) {
        devicesSubject.send(devices)
    }
}

private final class MockDeviceConnectionManagerForDeviceSettings: DeviceConnectionManagerProtocol {
    var connectCalled = false
    var disconnectCalled = false
    var sendCommandCalled = false
    var lastDevice: BluetoothDevice?
    
    var connectionStatePublisher: AnyPublisher<ConnectionState, Never> {
        connectionStateSubject.eraseToAnyPublisher()
    }
    var audioDataPublisher: AnyPublisher<Data, Never> {
        audioDataSubject.eraseToAnyPublisher()
    }
    
    private let connectionStateSubject = CurrentValueSubject<ConnectionState, Never>(.disconnected)
    private let audioDataSubject = PassthroughSubject<Data, Never>()
    
    func connect(to device: BluetoothDevice) {
        connectCalled = true
        lastDevice = device
        connectionStateSubject.send(.connecting)
        connectionStateSubject.send(.connected)
    }
    
    func disconnect() {
        disconnectCalled = true
        connectionStateSubject.send(.disconnected)
    }
    
    func sendCommand(_ command: Data) {
        sendCommandCalled = true
    }
    
    func mockSetConnectionState(_ state: ConnectionState) {
        connectionStateSubject.send(state)
    }
    
    func mockSendAudioData(_ data: Data) {
        audioDataSubject.send(data)
    }
}

private final class MockDeviceSettingsInteractorOutput: DeviceSettingsInteractorOutput {
    var discoveredDevices: [DeviceSettingsBluetoothDevice] = []
    var connectionState: DeviceSettingsConnectionState = .disconnected
    var error: Error?
    
    func didDiscoverDevices(_ devices: [DeviceSettingsBluetoothDevice]) {
        self.discoveredDevices = devices
    }
    
    func didUpdateConnectionState(_ state: DeviceSettingsConnectionState) {
        self.connectionState = state
    }
    
    func didFailWithError(_ error: Error) {
        self.error = error
    }
}

