import XCTest
@testable import Scribe

final class RecordingTests: XCTestCase {
    func testRecordingInitialization() {
        let recording = Recording(
            title: "Test Meeting",
            date: Date(),
            fileName: "test.caf",
            filePath: "/tmp/test.caf",
            source: .internalMic
        )
        
        XCTAssertEqual(recording.title, "Test Meeting")
        XCTAssertEqual(recording.fileName, "test.caf")
        XCTAssertEqual(recording.source, .internalMic)
        XCTAssertEqual(recording.duration, 0)
        XCTAssertNotNil(recording.id)
        XCTAssertNotNil(recording.createdAt)
    }
    
    func testRecordingSourceEnum() {
        XCTAssertEqual(RecordingSource.internalMic.rawValue, "internal_mic")
        XCTAssertEqual(RecordingSource.bleMicrophone.rawValue, "ble_microphone")
    }
}
