import XCTest
@testable import Scribe
import Combine

final class DeviceSettingsPresenterTests: XCTestCase {
    private var presenter: DeviceSettingsPresenter!
    private var mockInteractor: MockDeviceSettingsInteractorForPresenterTests!
    private var mockRouter: MockDeviceSettingsRouterForPresenterTests!
    
    override func setUp() {
        super.setUp()
        mockInteractor = MockDeviceSettingsInteractorForPresenterTests()
        mockRouter = MockDeviceSettingsRouterForPresenterTests()
        presenter = DeviceSettingsPresenter(
            view: nil,
            interactor: mockInteractor,
            router: mockRouter
        )
    }
    
    override func tearDown() {
        presenter = nil
        mockInteractor = nil
        mockRouter = nil
        super.tearDown()
    }
    
    func testDidTriggerViewReadyCallsInteractorStartScan() {
        presenter.didTriggerViewReady()
        XCTAssertTrue(mockInteractor.startScanCalled)
    }
    
    func testDidTapScanCallsInteractorStartScan() {
        presenter.didTapScan()
        XCTAssertTrue(mockInteractor.startScanCalled)
    }
    
    func testDidTapDeviceCallsInteractorConnectToDevice() {
        let device = DeviceSettingsBluetoothDevice(
            id: UUID(),
            name: "Test Device",
            rssi: -60
        )
        presenter.didTapDevice(device)
        XCTAssertTrue(mockInteractor.connectToDeviceCalled)
        XCTAssertEqual(mockInteractor.lastDevice?.name, "Test Device")
    }
    
    func testDidTapDisconnectCallsInteractorDisconnect() {
        presenter.didTapDisconnect()
        XCTAssertTrue(mockInteractor.disconnectCalled)
    }
    
    func testDisplayDevicesUpdatesStateAndCallsView() {
        let devices = [
            DeviceSettingsBluetoothDevice(id: UUID(), name: "Device 1", rssi: -50),
            DeviceSettingsBluetoothDevice(id: UUID(), name: "Device 2", rssi: -60)
        ]
        
        var viewDisplayDevicesCalled = false
        var displayedDevices: [DeviceSettingsBluetoothDevice] = []
        
        let mockView = MockDeviceSettingsViewInputForPresenterTests(
            displayDevicesCallback: { devices in
                viewDisplayDevicesCalled = true
                displayedDevices = devices
            }
        )
        
        presenter = DeviceSettingsPresenter(
            view: mockView,
            interactor: mockInteractor,
            router: mockRouter
        )
        
        presenter.displayDevices(devices)
        
        XCTAssertEqual(presenter.state.discoveredDevices.count, 2)
        XCTAssertTrue(viewDisplayDevicesCalled)
        XCTAssertEqual(displayedDevices.count, 2)
    }
    
    func testDisplayConnectionStateUpdatesStateAndCallsView() {
        let mockView = MockDeviceSettingsViewInputForPresenterTests(
            displayDevicesCallback: { _ in }
        )
        
        presenter = DeviceSettingsPresenter(
            view: mockView,
            interactor: mockInteractor,
            router: mockRouter
        )
        
        let testDevice = DeviceSettingsBluetoothDevice(id: UUID(), name: "Test", rssi: -60)
        presenter.displayConnectionState(.connected(testDevice))
        
        XCTAssertEqual(presenter.state.connectionState, .connected(testDevice))
    }
    
    func testDisplayErrorCallsView() {
        let error = NSError(domain: "Test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Test error"])
        
        var viewDisplayErrorCalled = false
        var displayedError: Error?
        
        let mockView = MockDeviceSettingsViewInputForPresenterTests(
            displayDevicesCallback: { _ in },
            displayErrorCallback: { (error: Error) in
                viewDisplayErrorCalled = true
                displayedError = error
            }
        )
        
        presenter = DeviceSettingsPresenter(
            view: mockView,
            interactor: mockInteractor,
            router: mockRouter
        )
        
        presenter.displayError(error)
        
        XCTAssertTrue(viewDisplayErrorCalled)
        XCTAssertEqual(displayedError as NSError?, error as NSError?)
    }
}

// MARK: - Mocks

private final class MockDeviceSettingsInteractorForPresenterTests: DeviceSettingsInteractorInput {
    var startScanCalled = false
    var connectToDeviceCalled = false
    var disconnectCalled = false
    var lastDevice: DeviceSettingsBluetoothDevice?
    
    func startScan() {
        startScanCalled = true
    }
    
    func connectToDevice(_ device: DeviceSettingsBluetoothDevice) {
        connectToDeviceCalled = true
        lastDevice = device
    }
    
    func disconnect() {
        disconnectCalled = true
    }
}

private final class MockDeviceSettingsRouterForPresenterTests: DeviceSettingsRouterInput {
    func closeCurrentModule() {}
}

private final class MockDeviceSettingsViewInputForPresenterTests: DeviceSettingsViewInput {
    let displayDevicesCallback: (([DeviceSettingsBluetoothDevice]) -> Void)?
    let displayErrorCallback: ((Error) -> Void)?
    
    init(
        displayDevicesCallback: (([DeviceSettingsBluetoothDevice]) -> Void)? = nil,
        displayErrorCallback: ((Error) -> Void)? = nil
    ) {
        self.displayDevicesCallback = displayDevicesCallback
        self.displayErrorCallback = displayErrorCallback
    }
    
    func displayDevices(_ devices: [DeviceSettingsBluetoothDevice]) {
        displayDevicesCallback?(devices)
    }
    
    func displayConnectionState(_ state: DeviceSettingsConnectionState) {}
    
    func displayError(_ error: Error) {
        displayErrorCallback?(error)
    }
}
