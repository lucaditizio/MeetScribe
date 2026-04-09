import Foundation
import CoreBluetooth
import Combine

/// BLE device scanner implementation
public final class BluetoothDeviceScanner: NSObject, BluetoothDeviceScannerProtocol {
    
    // MARK: - Publishers
    public var devicesPublisher: AnyPublisher<[BluetoothDevice], Never> {
        devicesSubject.eraseToAnyPublisher()
    }
    
    public var isScanningPublisher: AnyPublisher<Bool, Never> {
        isScanningSubject.eraseToAnyPublisher()
    }
    
    // MARK: - Private Properties
    private let devicesSubject = CurrentValueSubject<[BluetoothDevice], Never>([])
    private let isScanningSubject = CurrentValueSubject<Bool, Never>(false)
    private var centralManager: CBCentralManager?
    private var discoveredDevices: [String: BluetoothDevice] = [:]
    private let config = BluetoothConfig()
    
    // MARK: - Initialization
    public override init() {
        super.init()
        self.centralManager = CBCentralManager(delegate: self, queue: .main)
    }
    
    // MARK: - Public Methods
    public func startScan() {
        guard centralManager?.state == .poweredOn else {
            ScribeLogger.warning("Bluetooth not powered on", category: .ble)
            return
        }
        
        discoveredDevices.removeAll()
        devicesSubject.send([])
        
        // Scan for all devices, filter by name and RSSI later
        centralManager?.scanForPeripherals(
            withServices: nil,
            options: [CBCentralManagerScanOptionAllowDuplicatesKey: false]
        )
        
        isScanningSubject.send(true)
        ScribeLogger.info("Started BLE scan", category: .ble)
        
        // Auto-stop after timeout
        DispatchQueue.main.asyncAfter(deadline: .now() + config.connectionTimeout) { [weak self] in
            self?.stopScan()
        }
    }
    
    public func stopScan() {
        centralManager?.stopScan()
        isScanningSubject.send(false)
        ScribeLogger.info("Stopped BLE scan", category: .ble)
    }
}

// MARK: - CBCentralManagerDelegate
extension BluetoothDeviceScanner: CBCentralManagerDelegate {
    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            ScribeLogger.info("Bluetooth powered on", category: .ble)
        case .poweredOff:
            ScribeLogger.warning("Bluetooth powered off", category: .ble)
            stopScan()
        case .unauthorized:
            ScribeLogger.error("Bluetooth unauthorized", category: .ble)
        case .unsupported:
            ScribeLogger.error("Bluetooth unsupported", category: .ble)
        default:
            ScribeLogger.warning("Bluetooth state: \(central.state)", category: .ble)
        }
    }
    
    public func centralManager(
        _ central: CBCentralManager,
        didDiscover peripheral: CBPeripheral,
        advertisementData: [String: Any],
        rssi RSSI: NSNumber
    ) {
        let deviceName = peripheral.name ?? "Unknown"
        let rssiValue = RSSI.intValue
        
        // Filter by known device names
        guard config.knownDeviceNames.contains(deviceName) else {
            return
        }
        
        // Filter by RSSI threshold
        guard rssiValue >= config.rssiThreshold else {
            return
        }
        
        let device = BluetoothDevice(
            id: peripheral.identifier.uuidString,
            name: deviceName,
            rssi: rssiValue
        )
        
        discoveredDevices[peripheral.identifier.uuidString] = device
        devicesSubject.send(Array(discoveredDevices.values))
        
        ScribeLogger.debug("Discovered device: \(deviceName) (RSSI: \(rssiValue))", category: .ble)
    }
}
