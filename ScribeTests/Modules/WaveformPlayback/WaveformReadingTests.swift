import XCTest
import AVFoundation
@testable import Scribe

final class WaveformReadingTests: XCTestCase {
    func testReadAudio() async throws {
        let url = Bundle(for: type(of: self)).url(forResource: "test_audio", withExtension: "m4a")
        XCTAssertNotNil(url)
        let analyzer = WaveformAnalyzer()
        let samples = try await analyzer.analyze(url: url!, barCount: 50)
        XCTAssertEqual(samples.count, 50)
        print("SAMPLES COUNT:", samples.count)
    }
}
