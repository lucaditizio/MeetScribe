import XCTest
@testable import Scribe

final class LoggerTests: XCTestCase {
    func testScribeLoggerSingletonExists() {
        let logger = ScribeLogger.shared
        XCTAssertNotNil(logger)
    }
    
    func testScribeLoggerStaticMethods() {
        // These should not crash
        ScribeLogger.debug("Test debug message")
        ScribeLogger.info("Test info message")
        ScribeLogger.warning("Test warning message")
        ScribeLogger.error("Test error message")
        
        // Test with categories
        ScribeLogger.debug("BLE debug", category: .ble)
        ScribeLogger.info("Audio info", category: .audio)
        ScribeLogger.warning("ML warning", category: .ml)
        ScribeLogger.error("UI error", category: .ui)
        ScribeLogger.fault("Pipeline fault", category: .pipeline)
    }
    
    func testLogCategoryEnum() {
        let categories: [LogCategory] = [.ble, .audio, .ml, .ui, .pipeline, .general]
        XCTAssertEqual(categories.count, 6)
    }
}
