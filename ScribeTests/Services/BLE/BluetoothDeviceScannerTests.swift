import XCTest
import CoreBluetooth
@testable import Scribe

/// Mock CBCentralManager for testing
class MockCBCentralManager: CBCentralManager {
    var mockState: CBManagerState = .poweredOn
    var lastScanOptions: [String: Any]?
    var didStopScan = false
    
    override var state: CBManagerState {
        return mockState
    }
    
    override func scanForPeripherals(withServices serviceUUIDs: [CBUUID]?, options: [String : Any]?) {
        lastScanOptions = options
    }
    
    override func stopScan() {
        didStopScan = true
    }
}

final class BluetoothDeviceScannerTests: XCTestCase {
    func testScannerInitializes() {
        let scanner = BluetoothDeviceScanner()
        XCTAssertNotNil(scanner)
    }
    
    func testKnownDeviceIncluded() {
        // Test that "LA518" with RSSI -65 would be included
        let config = BluetoothConfig()
        let device = BluetoothDevice(id: "test-id", name: "LA518", rssi: -65)
        
        XCTAssertTrue(config.knownDeviceNames.contains(device.name))
        XCTAssertGreaterThanOrEqual(device.rssi, config.rssiThreshold)
    }
    
    func testUnknownDeviceExcluded() {
        // Test that "Unknown" device is excluded
        let config = BluetoothConfig()
        let deviceName = "UnknownDevice"
        
        XCTAssertFalse(config.knownDeviceNames.contains(deviceName))
    }
    
    func testWeakSignalExcluded() {
        // Test that "LA518" with RSSI -80 (below -70 threshold) is excluded
        let config = BluetoothConfig()
        let device = BluetoothDevice(id: "test-id", name: "LA518", rssi: -80)
        
        XCTAssertLessThan(device.rssi, config.rssiThreshold)
    }
    
    func testRSSIThresholdValue() {
        let config = BluetoothConfig()
        XCTAssertEqual(config.rssiThreshold, -70)
    }
    
    func testKnownDeviceNamesCount() {
        let config = BluetoothConfig()
        XCTAssertEqual(config.knownDeviceNames.count, 11)
    }
}
