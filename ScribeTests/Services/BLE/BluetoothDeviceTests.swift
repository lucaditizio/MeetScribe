import XCTest
@testable import Scribe

final class BluetoothDeviceTests: XCTestCase {
    func testBluetoothDeviceInitialization() {
        let id = UUID().uuidString
        let device = BluetoothDevice(
            id: id,
            name: "Test Device",
            rssi: -65
        )
        
        XCTAssertEqual(device.id, id)
        XCTAssertEqual(device.name, "Test Device")
        XCTAssertEqual(device.rssi, -65)
    }
    
    func testBluetoothDeviceIdentifiable() {
        let device = BluetoothDevice(
            id: UUID().uuidString,
            name: "LA518",
            rssi: -70
        )
        
        XCTAssertNotNil(device.id)
    }
    
    func testBluetoothDeviceSendable() {
        let device = BluetoothDevice(
            id: UUID().uuidString,
            name: "BLE Mic",
            rssi: -55
        )
        
        let sendableCheck: Sendable = device
        XCTAssertNotNil(sendableCheck)
    }
    
    func testBluetoothDeviceDifferentRSSI() {
        let strongSignal = BluetoothDevice(
            id: UUID().uuidString,
            name: "Nearby",
            rssi: -45
        )
        
        let weakSignal = BluetoothDevice(
            id: UUID().uuidString,
            name: "Far",
            rssi: -85
        )
        
        XCTAssertGreaterThan(strongSignal.rssi, weakSignal.rssi)
    }
}
