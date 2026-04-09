import XCTest
@testable import Scribe

final class SLinkChecksumTests: XCTestCase {
    func testChecksumCalculation() {
        // Test handshake command (0x0202 with empty payload)
        let checksum = SLinkChecksum.calculate(command: 0x0202, payload: [])
        // Expected: XOR of 0x0202 + length(0), then XOR 0x5F00
        // 0x0202 ^ 0x0000 = 0x0202
        // 0x0202 ^ 0x5F00 = 0x5D02
        XCTAssertEqual(checksum, 0x5D02)
    }
    
    func testChecksumWithPayload() {
        // Test configure command with known payload
        let payload: [UInt8] = [0x1A, 0x04, 0x04, 0x0E, 0x29, 0x32]
        let checksum = SLinkChecksum.calculate(command: 0x0204, payload: payload)
        // Verify checksum is non-zero and consistent
        XCTAssertNotEqual(checksum, 0)
        
        // Same input should produce same checksum
        let checksum2 = SLinkChecksum.calculate(command: 0x0204, payload: payload)
        XCTAssertEqual(checksum, checksum2)
    }
    
    func testChecksumConsistency() {
        // Verify deterministic behavior
        let payload: [UInt8] = [0x01, 0x02, 0x03]
        let checksum1 = SLinkChecksum.calculate(command: 0x0218, payload: payload)
        let checksum2 = SLinkChecksum.calculate(command: 0x0218, payload: payload)
        XCTAssertEqual(checksum1, checksum2)
    }
}
