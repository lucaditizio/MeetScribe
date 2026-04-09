import XCTest
@testable import Scribe

final class SLinkPacketParserTests: XCTestCase {
    func testParserFindsHeader() {
        let parser = SLinkPacketParser()
        
        // Create simple packet using serialize method to ensure correct format
        let packet = SLinkPacket(command: 0x0202, payload: [])
        let data = packet.serialize()
        
        let packets = parser.feed(data)
        XCTAssertEqual(packets.count, 1, "Parser should return one packet")
        if !packets.isEmpty {
            XCTAssertEqual(packets.first?.command, 0x0202)
        }
    }
    
    func testParserWithPayload() {
        let parser = SLinkPacketParser()
        
        // Create packet with payload using serialize method
        let packet = SLinkPacket(command: 0x0204, payload: [0x1A, 0x04, 0x04, 0x0E, 0x29, 0x32])
        
        let packets = parser.feed(packet.serialize())
        XCTAssertEqual(packets.count, 1)
        XCTAssertEqual(packets.first?.command, 0x0204)
        XCTAssertEqual(packets.first?.payload, [0x1A, 0x04, 0x04, 0x0E, 0x29, 0x32])
    }
    
    func testParserMultiplePackets() {
        let parser = SLinkPacketParser()
        
        // Create two handshake packets using serialize method
        let packet1 = SLinkPacket(command: 0x0202, payload: [])
        let packet2 = SLinkPacket(command: 0x0202, payload: [])
        
        var data = Data()
        data.append(packet1.serialize())
        data.append(packet2.serialize())
        
        let packets = parser.feed(data)
        XCTAssertEqual(packets.count, 2)
    }
    
    func testParserInvalidChecksum() {
        let parser = SLinkPacketParser()
        
        // Create packet with invalid checksum
        var data = Data([0x80, 0x08])  // header
        data.append(contentsOf: [0x02, 0x02])  // command
        data.append(contentsOf: [0x00, 0x00])  // length
        data.append(contentsOf: [0xFF, 0xFF])  // wrong checksum
        
        let packets = parser.feed(data)
        XCTAssertEqual(packets.count, 0)  // Should not parse invalid packet
    }
}
