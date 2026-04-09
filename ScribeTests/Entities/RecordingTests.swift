import XCTest
@testable import Scribe

final class RecordingTests: XCTestCase {
    func testRecordingInitialization() {
        let recording = Recording(
            title: "Test Meeting",
            date: Date(),
            fileName: "test.caf",
            filePath: "/tmp/test.caf",
            source: .rawInternal
        )
        
        XCTAssertEqual(recording.title, "Test Meeting")
        XCTAssertEqual(recording.fileName, "test.caf")
        XCTAssertEqual(recording.source, .rawInternal)
        XCTAssertEqual(recording.duration, 0)
        XCTAssertNotNil(recording.id)
        XCTAssertNotNil(recording.createdAt)
    }
    
    func testRecordingSourceEnum() {
        XCTAssertEqual(RecordingSource.rawInternal.rawValue, "internal")
        XCTAssertEqual(RecordingSource.rawBle.rawValue, "ble")
    }
}
