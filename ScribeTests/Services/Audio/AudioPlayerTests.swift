import XCTest
import Combine
import AVFoundation
@testable import Scribe

final class AudioPlayerTests: XCTestCase {
    private var player: AudioPlayer!
    private var cancellables: Set<AnyCancellable>!
    private var testAudioURL: URL!

    override func setUp() async throws {
        try await super.setUp()
        player = AudioPlayer()
        cancellables = []
        testAudioURL = try createTestAudioFile()
    }

    override func tearDown() {
        cancellables = nil
        player = nil
        if let url = testAudioURL {
            try? FileManager.default.removeItem(at: url)
        }
        testAudioURL = nil
        super.tearDown()
    }

    // MARK: - Speed Cycling Tests

    func testSpeedCyclingFrom1xTo1_5x() async throws {
        loadTestAudio()
        var receivedRates: [Float] = []

        player.play()
        receivedRates.append(try await getCurrentRate())

        XCTAssertEqual(receivedRates.last, 1.5, "First play should cycle to 1.5x")
    }

    func testSpeedCyclingFrom1_5xTo2x() async throws {
        loadTestAudio()
        var receivedRates: [Float] = []

        player.play()
        receivedRates.append(try await getCurrentRate())

        player.play()
        receivedRates.append(try await getCurrentRate())

        XCTAssertEqual(receivedRates[1], 2.0, "Second play should cycle to 2.0x")
    }

    func testSpeedCyclingFrom2xTo1x() async throws {
        loadTestAudio()
        var receivedRates: [Float] = []

        player.play()
        receivedRates.append(try await getCurrentRate())

        player.play()
        receivedRates.append(try await getCurrentRate())

        player.play()
        receivedRates.append(try await getCurrentRate())

        XCTAssertEqual(receivedRates[2], 1.0, "Third play should cycle back to 1.0x")
    }

    func testSpeedCyclingFullCycle() async throws {
        loadTestAudio()
        var receivedRates: [Float] = []

        for _ in 0..<4 {
            player.play()
            receivedRates.append(try await getCurrentRate())
        }

        XCTAssertEqual(receivedRates, [1.5, 2.0, 1.0, 1.5], "Speed should cycle through 1.5, 2.0, 1.0, 1.5")
    }

    // MARK: - Play/Pause/Stop Lifecycle Tests

    func testInitialStateIsIdle() {
        var initialState: PlaybackState?

        player.playbackStatePublisher
            .first()
            .sink { state in
                initialState = state
            }
            .store(in: &cancellables)

        XCTAssertTrue(isState(initialState, equalTo: .idle), "Initial state should be idle")
    }

    func testLoadSetsStateToIdleAfterLoading() {
        var states: [PlaybackState] = []

        player.playbackStatePublisher
            .sink { state in
                states.append(state)
            }
            .store(in: &cancellables)

        loadTestAudio()

        XCTAssertTrue(containsState(states, matching: .loading), "Should emit loading state")
        XCTAssertTrue(containsState(states, matching: .idle), "Should emit idle state after loading")
    }

    func testPlaySetsStateToPlaying() {
        var states: [PlaybackState] = []

        player.playbackStatePublisher
            .sink { state in
                states.append(state)
            }
            .store(in: &cancellables)

        loadTestAudio()
        player.play()

        XCTAssertTrue(containsState(states, matching: .playing), "Should emit playing state after play()")
    }

    func testPauseSetsStateToPaused() {
        var states: [PlaybackState] = []

        player.playbackStatePublisher
            .sink { state in
                states.append(state)
            }
            .store(in: &cancellables)

        loadTestAudio()
        player.play()
        player.pause()

        XCTAssertTrue(containsState(states, matching: .paused), "Should emit paused state after pause()")
    }

    func testStopSetsStateToIdle() {
        var states: [PlaybackState] = []

        player.playbackStatePublisher
            .sink { state in
                states.append(state)
            }
            .store(in: &cancellables)

        loadTestAudio()
        player.play()
        player.stop()

        XCTAssertTrue(containsState(states, matching: .idle), "Should emit idle state after stop()")
    }

    func testStopResetsCurrentTimeToZero() {
        var currentTime: TimeInterval = -1

        player.currentTimePublisher
            .sink { time in
                currentTime = time
            }
            .store(in: &cancellables)

        loadTestAudio()
        player.play()
        player.seek(to: 5.0)
        player.stop()

        XCTAssertEqual(currentTime, 0.0, "Stop should reset current time to 0")
    }

    // MARK: - Seek Tests

    func testSeekUpdatesCurrentTime() {
        var currentTime: TimeInterval = -1

        player.currentTimePublisher
            .sink { time in
                currentTime = time
            }
            .store(in: &cancellables)

        loadTestAudio()
        player.seek(to: 10.0)

        XCTAssertEqual(currentTime, 10.0, "Seek should update current time to 10.0")
    }

    func testSeekToZero() {
        var currentTime: TimeInterval = -1

        player.currentTimePublisher
            .sink { time in
                currentTime = time
            }
            .store(in: &cancellables)

        loadTestAudio()
        player.seek(to: 0.0)

        XCTAssertEqual(currentTime, 0.0, "Seek to 0 should work")
    }

    func testSeekToMaximumDuration() async throws {
        var currentTime: TimeInterval = -1

        player.currentTimePublisher
            .sink { time in
                currentTime = time
            }
            .store(in: &cancellables)

        loadTestAudio()
        let duration = try await getAudioDuration()
        player.seek(to: duration)

        XCTAssertEqual(currentTime, duration, "Seek to duration should work")
    }

    // MARK: - Skip Forward Tests

    func testSkipForwardAdds15Seconds() {
        var currentTime: TimeInterval = -1

        player.currentTimePublisher
            .sink { time in
                currentTime = time
            }
            .store(in: &cancellables)

        loadTestAudio()
        player.seek(to: 0.0)
        player.skipForward()

        XCTAssertEqual(currentTime, 15.0, "Skip forward should add 15 seconds")
    }

    func testSkipForwardFromMiddlePosition() {
        var currentTime: TimeInterval = -1

        player.currentTimePublisher
            .sink { time in
                currentTime = time
            }
            .store(in: &cancellables)

        loadTestAudio()
        player.seek(to: 10.0)
        player.skipForward()

        XCTAssertEqual(currentTime, 25.0, "Skip forward from 10s should go to 25s")
    }

    func testSkipForwardClampsToDuration() async throws {
        var currentTime: TimeInterval = -1

        player.currentTimePublisher
            .sink { time in
                currentTime = time
            }
            .store(in: &cancellables)

        loadTestAudio()
        let duration = try await getAudioDuration()
        let nearEnd = duration - 5.0
        player.seek(to: nearEnd)
        player.skipForward()

        XCTAssertEqual(currentTime, duration, "Skip forward near end should clamp to duration")
    }

    // MARK: - Skip Backward Tests

    func testSkipBackwardSubtracts15Seconds() {
        var currentTime: TimeInterval = -1

        player.currentTimePublisher
            .sink { time in
                currentTime = time
            }
            .store(in: &cancellables)

        loadTestAudio()
        player.seek(to: 30.0)
        player.skipBackward()

        XCTAssertEqual(currentTime, 15.0, "Skip backward should subtract 15 seconds")
    }

    func testSkipBackwardFromMiddlePosition() {
        var currentTime: TimeInterval = -1

        player.currentTimePublisher
            .sink { time in
                currentTime = time
            }
            .store(in: &cancellables)

        loadTestAudio()
        player.seek(to: 20.0)
        player.skipBackward()

        XCTAssertEqual(currentTime, 5.0, "Skip backward from 20s should go to 5s")
    }

    func testSkipBackwardClampsToZero() {
        var currentTime: TimeInterval = -1

        player.currentTimePublisher
            .sink { time in
                currentTime = time
            }
            .store(in: &cancellables)

        loadTestAudio()
        player.seek(to: 10.0)
        player.skipBackward()

        XCTAssertEqual(currentTime, 0.0, "Skip backward from 10s should clamp to 0")
    }

    func testSkipBackwardFromZeroStaysAtZero() {
        var currentTime: TimeInterval = -1

        player.currentTimePublisher
            .sink { time in
                currentTime = time
            }
            .store(in: &cancellables)

        loadTestAudio()
        player.seek(to: 0.0)
        player.skipBackward()

        XCTAssertEqual(currentTime, 0.0, "Skip backward from 0 should stay at 0")
    }

    // MARK: - Error Handling Tests

    func testPlayWithoutLoadDoesNotCrash() {
        var errorReceived = false

        player.playbackStatePublisher
            .sink { state in
                if case .error = state {
                    errorReceived = true
                }
            }
            .store(in: &cancellables)

        player.play()

        XCTAssertFalse(errorReceived, "Play without load should silently fail, not emit error")
    }

    func testPauseWithoutLoadDoesNotCrash() {
        player.pause()
    }

    func testStopWithoutLoadDoesNotCrash() {
        player.stop()
    }

    func testSeekWithoutLoadDoesNotCrash() {
        player.seek(to: 10.0)
    }

    // MARK: - Helper Methods

    private func createTestAudioFile() throws -> URL {
        let tempDir = FileManager.default.temporaryDirectory
        let fileName = "test_audio_\(UUID().uuidString).caf"
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
            throw NSError(domain: "AudioPlayerTests", code: -1, userInfo: nil)
        }

        let frameCount: AVAudioFrameCount = 44100 * 60
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else {
            throw NSError(domain: "AudioPlayerTests", code: -2, userInfo: nil)
        }
        buffer.frameLength = frameCount

        guard let channelData = buffer.floatChannelData else {
            throw NSError(domain: "AudioPlayerTests", code: -3, userInfo: nil)
        }
        memset(channelData[0], 0, Int(frameCount) * MemoryLayout<Float>.size)

        try audioFile.write(from: buffer)

        return fileURL
    }

    private func loadTestAudio() {
        guard let url = testAudioURL else {
            XCTFail("Test audio URL is nil")
            return
        }
        player.load(url: url)
    }

    private func getCurrentRate() async throws -> Float {
        let mirror = Mirror(reflecting: player)
        var foundMirror: Mirror? = mirror
        while let m = foundMirror {
            for child in m.children {
                if child.label == "currentRate" {
                    guard let rate = child.value as? Float else {
                        throw NSError(domain: "AudioPlayerTests", code: -5, userInfo: nil)
                    }
                    return rate
                }
            }
            foundMirror = m.superclassMirror
        }
        throw NSError(domain: "AudioPlayerTests", code: -6, userInfo: [NSLocalizedDescriptionKey: "currentRate property not found"])
    }

    private func getAudioDuration() async throws -> TimeInterval {
        guard let url = testAudioURL else {
            throw NSError(domain: "AudioPlayerTests", code: -4, userInfo: nil)
        }
        let asset = AVURLAsset(url: url)
        let duration = try await asset.load(.duration)
        return CMTimeGetSeconds(duration)
    }

    private func isState(_ state: PlaybackState?, equalTo expected: PlaybackState) -> Bool {
        guard let state = state else { return false }
        switch (state, expected) {
        case (.idle, .idle), (.loading, .loading), (.playing, .playing), (.paused, .paused):
            return true
        case (.error, .error):
            return true
        default:
            return false
        }
    }

    private func containsState(_ states: [PlaybackState], matching expected: PlaybackState) -> Bool {
        for state in states {
            if isState(state, equalTo: expected) {
                return true
            }
        }
        return false
    }
}