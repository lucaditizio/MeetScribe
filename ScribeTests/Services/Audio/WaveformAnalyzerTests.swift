import XCTest
import AVFoundation
@testable import Scribe

final class WaveformAnalyzerTests: XCTestCase {
    private var analyzer: WaveformAnalyzer!
    private var testAudioURL: URL!

    override func setUp() async throws {
        try await super.setUp()
        analyzer = WaveformAnalyzer()
        testAudioURL = try createTestAudioFile()
    }

    override func tearDown() {
        if let url = testAudioURL {
            try? FileManager.default.removeItem(at: url)
        }
        testAudioURL = nil
        analyzer = nil
        super.tearDown()
    }

    // MARK: - Waveform Bar Count Tests

    func testWaveformProduces50Bars() async throws {
        let samples = try await analyzer.analyze(url: testAudioURL, barCount: 50)

        XCTAssertEqual(samples.count, 50, "Should produce exactly 50 bars")
    }

    func testWaveformProducesCustomBarCount() async throws {
        let samples = try await analyzer.analyze(url: testAudioURL, barCount: 100)

        XCTAssertEqual(samples.count, 100, "Should produce exactly 100 bars when specified")
    }

    func testWaveformProducesOneBar() async throws {
        let samples = try await analyzer.analyze(url: testAudioURL, barCount: 1)

        XCTAssertEqual(samples.count, 1, "Should produce exactly 1 bar when specified")
    }

    // MARK: - Normalization Tests

    func testWaveformNormalizedToMinRange() async throws {
        let samples = try await analyzer.analyze(url: testAudioURL, barCount: 50)

        for sample in samples {
            XCTAssertGreaterThanOrEqual(sample.value, 0.05, "All values should be >= 0.05")
        }
    }

    func testWaveformNormalizedToMaxRange() async throws {
        let samples = try await analyzer.analyze(url: testAudioURL, barCount: 50)

        for sample in samples {
            XCTAssertLessThanOrEqual(sample.value, 1.0, "All values should be <= 1.0")
        }
    }

    func testWaveformAllValuesInRange() async throws {
        let samples = try await analyzer.analyze(url: testAudioURL, barCount: 50)

        for (index, sample) in samples.enumerated() {
            XCTAssertTrue(
                sample.value >= 0.05 && sample.value <= 1.0,
                "Sample at index \(index) value \(sample.value) not in range [0.05, 1.0]"
            )
        }
    }

    // MARK: - Timestamp Tests

    func testWaveformTimestampsStartAtZero() async throws {
        let samples = try await analyzer.analyze(url: testAudioURL, barCount: 50)

        XCTAssertEqual(samples.first?.timestamp, 0.0, "First timestamp should be 0")
    }

    func testWaveformTimestampsAreMonotonicallyIncreasing() async throws {
        let samples = try await analyzer.analyze(url: testAudioURL, barCount: 50)

        for i in 0..<(samples.count - 1) {
            XCTAssertLessThanOrEqual(
                samples[i].timestamp,
                samples[i + 1].timestamp,
                "Timestamps should be monotonically increasing"
            )
        }
    }

    // MARK: - Error Handling Tests

    func testInvalidFilePathThrowsFileNotFound() async {
        let invalidURL = URL(fileURLWithPath: "/nonexistent/path/audio.caf")

        do {
            _ = try await analyzer.analyze(url: invalidURL, barCount: 50)
            XCTFail("Should throw fileNotFound error")
        } catch let error as WaveformAnalyzerError {
            if case .fileNotFound = error {
            } else {
                XCTFail("Expected fileNotFound error, got \(error)")
            }
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func testNonAudioFileThrowsError() async {
        let tempDir = FileManager.default.temporaryDirectory
        let textFileURL = tempDir.appendingPathComponent("test_\(UUID().uuidString).txt")

        do {
            try "not an audio file".write(to: textFileURL, atomically: true, encoding: .utf8)

            do {
                _ = try await analyzer.analyze(url: textFileURL, barCount: 50)
                XCTFail("Should throw error for non-audio file")
            } catch {
            }
        } catch {
            XCTFail("Failed to create test file: \(error)")
        }

        try? FileManager.default.removeItem(at: textFileURL)
    }

    // MARK: - AudioSample Structure Tests

    func testAudioSampleHasValue() async throws {
        let samples = try await analyzer.analyze(url: testAudioURL, barCount: 50)

        for sample in samples {
            XCTAssertNotNil(sample.value, "AudioSample should have a value")
        }
    }

    func testAudioSampleHasTimestamp() async throws {
        let samples = try await analyzer.analyze(url: testAudioURL, barCount: 50)

        for sample in samples {
            XCTAssertNotNil(sample.timestamp, "AudioSample should have a timestamp")
        }
    }

    // MARK: - Helper Methods

    private func createTestAudioFile() throws -> URL {
        let tempDir = FileManager.default.temporaryDirectory
        let fileName = "test_waveform_\(UUID().uuidString).caf"
        let fileURL = tempDir.appendingPathComponent(fileName)

        let format = AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: 44100,
            channels: 1,
            interleaved: false
        )!

        guard let audioFile = try? AVAudioFile(
            forWriting: fileURL,
            settings: format.settings
        ) else {
            throw NSError(domain: "WaveformAnalyzerTests", code: -1, userInfo: nil)
        }

        let frameCount: AVAudioFrameCount = 44100 * 5
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else {
            throw NSError(domain: "WaveformAnalyzerTests", code: -2, userInfo: nil)
        }
        buffer.frameLength = frameCount

        guard let channelData = buffer.floatChannelData else {
            throw NSError(domain: "WaveformAnalyzerTests", code: -3, userInfo: nil)
        }

        for i in 0..<Int(frameCount) {
            let t = Float(i) / Float(frameCount)
            channelData[0][i] = sin(2.0 * Float.pi * 440.0 * t)
        }

        try audioFile.write(from: buffer)

        return fileURL
    }
}