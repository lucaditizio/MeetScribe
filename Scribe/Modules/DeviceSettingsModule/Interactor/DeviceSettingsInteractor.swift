import Foundation
import Combine

// MARK: - DeviceSettingsInteractor

/// Interactor for DeviceSettingsModule - handles BLE scanning and connection logic
public final class DeviceSettingsInteractor: DeviceSettingsInteractorInput {
    
    // MARK: - Weak Output Reference (VIPER Convention)
    public weak var output: DeviceSettingsInteractorOutput?
    
    // MARK: - Strong Service References
    private let scanner: BluetoothDeviceScannerProtocol
    private let connectionManager: DeviceConnectionManagerProtocol
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    private var currentDevice: DeviceSettingsBluetoothDevice?
    
    // MARK: - Initialization
    public init(
        scanner: BluetoothDeviceScannerProtocol = BluetoothDeviceScanner(),
        connectionManager: DeviceConnectionManagerProtocol = DeviceConnectionManager()
    ) {
        self.scanner = scanner
        self.connectionManager = connectionManager
        setupSubscriptions()
    }
    
    // MARK: - Public Methods (DeviceSettingsInteractorInput)
    
    public func startScan() {
        ScribeLogger.info("Starting BLE device scan", category: .ble)
        scanner.startScan()
    }
    
    public func connectToDevice(_ device: DeviceSettingsBluetoothDevice) {
        ScribeLogger.info("Connecting to device: \(device.name)", category: .ble)
        
        self.currentDevice = device
        
        // Convert DeviceSettingsBluetoothDevice to BluetoothDevice for connection manager
        let bluetoothDevice = BluetoothDevice(
            id: device.id.uuidString,
            name: device.name,
            rssi: device.rssi
        )
        
        connectionManager.connect(to: bluetoothDevice)
    }
    
    public func disconnect() {
        ScribeLogger.info("Disconnecting from current device", category: .ble)
        connectionManager.disconnect()
        currentDevice = nil
    }
    
    // MARK: - Private Methods
    
    private func setupSubscriptions() {
        // Subscribe to discovered devices
        scanner.devicesPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] devices in
                self?.handleDiscoveredDevices(devices)
            }
            .store(in: &cancellables)
        
        // Subscribe to connection state changes
        connectionManager.connectionStatePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.handleConnectionState(state)
            }
            .store(in: &cancellables)
    }
    
    private func handleDiscoveredDevices(_ devices: [BluetoothDevice]) {
        // Convert BluetoothDevice to DeviceSettingsBluetoothDevice
        let deviceSettingsDevices = devices.map { device in
            DeviceSettingsBluetoothDevice(
                id: UUID(uuidString: device.id) ?? UUID(),
                name: device.name,
                rssi: device.rssi
            )
        }
        
        ScribeLogger.debug("Discovered \(deviceSettingsDevices.count) devices", category: .ble)
        output?.didDiscoverDevices(deviceSettingsDevices)
    }
    
    private func handleConnectionState(_ state: ConnectionState) {
        let deviceSettingsState: DeviceSettingsConnectionState
        
        switch state {
        case .disconnected:
            deviceSettingsState = .disconnected
            ScribeLogger.info("Device disconnected", category: .ble)
            
        case .connecting:
            deviceSettingsState = .connecting
            ScribeLogger.debug("Connecting to device...", category: .ble)
            
        case .connected:
            deviceSettingsState = .connected(currentDevice ?? .init(name: "Unknown", rssi: 0))
            ScribeLogger.info("Device connected successfully", category: .ble)
            
        case .binding:
            deviceSettingsState = .connected(currentDevice ?? .init(name: "Unknown", rssi: 0))
            ScribeLogger.debug("Binding to device...", category: .ble)
            
        case .initializing:
            deviceSettingsState = .connected(currentDevice ?? .init(name: "Unknown", rssi: 0))
            ScribeLogger.debug("Initializing device...", category: .ble)
            
        case .initialized:
            deviceSettingsState = .connected(currentDevice ?? .init(name: "Unknown", rssi: 0))
            ScribeLogger.info("Device initialized", category: .ble)
            
        case .bound:
            deviceSettingsState = .connected(currentDevice ?? .init(name: "Unknown", rssi: 0))
            ScribeLogger.info("Device bound successfully", category: .ble)
            
        case .failed(let errorMessage):
            deviceSettingsState = .disconnected
            ScribeLogger.error("Connection failed: \(errorMessage)", category: .ble)
            output?.didFailWithError(NSError(domain: "DeviceSettingsInteractor", code: 1, userInfo: [NSLocalizedDescriptionKey: errorMessage]))
            
        case .reconnecting(let attempt):
            deviceSettingsState = .connecting
            ScribeLogger.warning("Reconnection attempt \(attempt)", category: .ble)
        }
        
        output?.didUpdateConnectionState(deviceSettingsState)
    }
}
