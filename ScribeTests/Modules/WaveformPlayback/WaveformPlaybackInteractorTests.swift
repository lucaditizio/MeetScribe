import XCTest
@testable import Scribe

final class WaveformPlaybackInteractorTests: XCTestCase {
    private var interactor: WaveformPlaybackInteractor!
    private var mockOutput: MockInteractorOutput!
    private var mockWaveformAnalyzer: MockWaveformAnalyzer!
    
    override func setUp() {
        super.setUp()
        mockOutput = MockInteractorOutput()
        mockWaveformAnalyzer = MockWaveformAnalyzer()
        interactor = WaveformPlaybackInteractor(
            output: mockOutput,
            audioPlayer: MockAudioPlayer(),
            waveformAnalyzer: mockWaveformAnalyzer
        )
    }
    
    func testPlayAudioCallsPlayerPlay() {
        interactor.playAudio()
        XCTAssertTrue(mockOutput.isPlaying)
    }
    
    func testPauseAudioCallsPlayerPause() {
        interactor.pauseAudio()
        XCTAssertFalse(mockOutput.isPlaying)
    }
    
    func testSeekToCallsPlayerSeek() {
        interactor.seekTo(30.0)
        XCTAssertEqual(mockOutput.currentTime, 30.0, accuracy: 0.1)
    }
    
    func testCycleSpeedChangesSpeed() {
        interactor.cycleSpeed()
        XCTAssertTrue(mockOutput.isPlaying)
    }
}

private final class MockInteractorOutput: WaveformPlaybackInteractorOutput {
    var waveformBars: [Float] = []
    var isPlaying = false
    var currentTime: TimeInterval = 0
    
    func didObtainWaveformData(_ bars: [Float]) { self.waveformBars = bars }
    func didUpdatePlaybackState(isPlaying: Bool, currentTime: TimeInterval) {
        self.isPlaying = isPlaying
        self.currentTime = currentTime
    }
    func didFailWithError(_ error: Error) {}
}

private final class MockWaveformAnalyzer: WaveformAnalyzerProtocol {
    func analyze(url: URL, barCount: Int) async throws -> [AudioSample] { [] }
}
