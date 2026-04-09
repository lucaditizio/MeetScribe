import XCTest
@testable import Scribe

final class ExtensionTests: XCTestCase {
    // MARK: - TimeInterval Tests
    func testTimeIntervalFormatting() {
        XCTAssertEqual(TimeInterval(0).formattedDuration, "0:00")
        XCTAssertEqual(TimeInterval(65).formattedDuration, "1:05")
        XCTAssertEqual(TimeInterval(3661).formattedDuration, "1:01:01")
        XCTAssertEqual(TimeInterval(3600).formattedDuration, "1:00:00")
    }
    
    // MARK: - String Tests
    func testStringValidation() {
        XCTAssertTrue("valid".isValidFilename)
        XCTAssertFalse("invalid/name".isValidFilename)
        XCTAssertFalse("".isValidFilename)
        XCTAssertTrue("recording-2024".isValidFilename)
    }
    
    func testStringTruncation() {
        XCTAssertEqual("short".truncated(to: 10), "short")
        XCTAssertEqual("very long string".truncated(to: 5), "very ...")
    }
    
    // MARK: - Date Tests
    func testDateFormatting() {
        let date = Date(timeIntervalSince1970: 0)
        XCTAssertFalse(date.formattedDisplay.isEmpty)
        XCTAssertFalse(date.formattedForFilename.isEmpty)
    }
}
