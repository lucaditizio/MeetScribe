import Foundation
import CoreBluetooth
import Combine

/// Manages BLE device connection lifecycle with reconnection and persistence
public final class DeviceConnectionManager: NSObject, DeviceConnectionManagerProtocol {
    
    // MARK: - Publishers
    public var connectionStatePublisher: AnyPublisher<ConnectionState, Never> {
        connectionStateSubject.eraseToAnyPublisher()
    }
    
    public var audioDataPublisher: AnyPublisher<Data, Never> {
        audioDataSubject.eraseToAnyPublisher()
    }
    
    // MARK: - Private Properties
    private let connectionStateSubject = CurrentValueSubject<ConnectionState, Never>(.disconnected)
    private let audioDataSubject = PassthroughSubject<Data, Never>()
    private var centralManager: CBCentralManager?
    private var connectedPeripheral: CBPeripheral?
    private var stateMachine: ConnectionStateMachine?
    private var orchestrator: SLinkInitOrchestrator?
    private var keepAliveService: KeepAliveService?
    private let config = BluetoothConfig()
    private var connectionTimeoutTimer: Timer?
    private var pendingDevice: BluetoothDevice?
    
    // MARK: - UserDefaults Keys
    private let lastConnectedDeviceIDKey = "lastConnectedDeviceID"
    
    // MARK: - Initialization
    public override init() {
        super.init()
        self.centralManager = CBCentralManager(delegate: self, queue: .main)
        self.stateMachine = ConnectionStateMachine()
    }
    
    // MARK: - Public Methods
    
    public func connect(to device: BluetoothDevice) {
        guard centralManager?.state == .poweredOn else {
            connectionStateSubject.send(.failed("Bluetooth not powered on"))
            return
        }
        
        // Store device for potential reconnection
        pendingDevice = device
        saveLastConnectedDevice(device)
        
        connectionStateSubject.send(.connecting)
        stateMachine?.startConnecting()
        
        // Find peripheral by identifier
        guard let uuid = UUID(uuidString: device.id) else {
            connectionStateSubject.send(.failed("Invalid device UUID"))
            return
        }
        
        let peripherals = centralManager?.retrievePeripherals(withIdentifiers: [uuid])
        
        guard let peripheral = peripherals?.first else {
            connectionStateSubject.send(.failed("Device not found"))
            return
        }
        
        connectedPeripheral = peripheral
        centralManager?.connect(peripheral, options: nil)
        
        // Start connection timeout timer (10s)
        startConnectionTimeout()
        
        ScribeLogger.info("Connecting to device: \(device.name)", category: .ble)
    }
    
    public func disconnect() {
        connectionTimeoutTimer?.invalidate()
        connectionTimeoutTimer = nil
        keepAliveService?.stop()
        
        guard let peripheral = connectedPeripheral else {
            return
        }
        
        centralManager?.cancelPeripheralConnection(peripheral)
        ScribeLogger.info("Disconnecting from device", category: .ble)
    }
    
    public func sendCommand(_ command: Data) {
        guard let peripheral = connectedPeripheral else {
            ScribeLogger.error("No peripheral connected", category: .ble)
            return
        }
        
        ScribeLogger.debug("Sending command: \(command.hexString)", category: .ble)
    }
    
    /// Get the last connected device ID from UserDefaults
    public func getLastConnectedDeviceID() -> String? {
        return UserDefaults.standard.string(forKey: lastConnectedDeviceIDKey)
    }
    
    // MARK: - Private Methods
    
    private func saveLastConnectedDevice(_ device: BluetoothDevice) {
        UserDefaults.standard.set(device.id, forKey: lastConnectedDeviceIDKey)
    }
    
    private func startConnectionTimeout() {
        connectionTimeoutTimer?.invalidate()
        connectionTimeoutTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            
            ScribeLogger.error("Connection timed out after 10s", category: .ble)
            
            // Attempt reconnection if max attempts not reached
            if self.stateMachine?.attemptReconnection() == true {
                ScribeLogger.info("Attempting reconnection...", category: .ble)
                if let device = self.pendingDevice {
                    self.connect(to: device)
                }
            } else {
                self.connectionStateSubject.send(.failed("Connection timeout - max reconnection attempts reached"))
            }
        }
    }
    
    private func startInitialization() {
        guard let stateMachine = stateMachine else { return }
        
        orchestrator = SLinkInitOrchestrator(
            stateMachine: stateMachine,
            commandDelay: SLinkConstants.commandDelay,
            stepTimeout: config.sLinkTimeout
        )
        
        orchestrator?.startInitialization { [weak self] command in
            let packet = SLinkPacket(command: command.rawValue, payload: command.defaultPayload)
            self?.sendCommand(packet.serialize())
        }
        
        // Setup keepalive after initialization
        setupKeepAlive()
    }
    
    private func setupKeepAlive() {
        keepAliveService = KeepAliveService(interval: 3.0) { [weak self] in
            let keepAliveCommand = Data([0x80, 0x08, 0x02, 0x17, 0x00, 0x01, 0x00, 0x00])
            self?.sendCommand(keepAliveCommand)
        }
        keepAliveService?.start()
    }
}

// MARK: - CBCentralManagerDelegate
extension DeviceConnectionManager: CBCentralManagerDelegate {
    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            ScribeLogger.info("Bluetooth powered on", category: .ble)
        case .poweredOff:
            ScribeLogger.warning("Bluetooth powered off", category: .ble)
            disconnect()
        case .unauthorized:
            ScribeLogger.error("Bluetooth unauthorized", category: .ble)
        case .unsupported:
            ScribeLogger.error("Bluetooth unsupported", category: .ble)
        default:
            break
        }
    }
    
    public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        connectionTimeoutTimer?.invalidate()
        connectionTimeoutTimer = nil
        
        connectionStateSubject.send(.connected)
        stateMachine?.markConnected()
        
        ScribeLogger.info("Connected to device", category: .ble)
        
        // Start SLink initialization
        startInitialization()
    }
    
    public func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        connectionTimeoutTimer?.invalidate()
        
        let errorMessage = error?.localizedDescription ?? "Unknown error"
        ScribeLogger.error("Failed to connect: \(errorMessage)", category: .ble)
        
        // Attempt reconnection
        if stateMachine?.attemptReconnection() == true {
            if let device = pendingDevice {
                connect(to: device)
            }
        } else {
            connectionStateSubject.send(.failed("Failed to connect: \(errorMessage)"))
        }
    }
    
    public func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        connectionTimeoutTimer?.invalidate()
        keepAliveService?.stop()
        
        if let error = error {
            ScribeLogger.error("Disconnected with error: \(error.localizedDescription)", category: .ble)
            
            // Attempt reconnection on unexpected disconnect
            if stateMachine?.attemptReconnection() == true {
                if let device = pendingDevice {
                    connect(to: device)
                }
                return
            }
        }
        
        connectionStateSubject.send(.disconnected)
        ScribeLogger.info("Disconnected from device", category: .ble)
    }
}

// MARK: - Data Extension
private extension Data {
    var hexString: String {
        return map { String(format: "%02x", $0) }.joined()
    }
}
