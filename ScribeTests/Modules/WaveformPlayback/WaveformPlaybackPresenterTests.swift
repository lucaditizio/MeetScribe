import XCTest
@testable import Scribe

final class WaveformPlaybackPresenterTests: XCTestCase {
    private var presenter: WaveformPlaybackPresenter!
    private var mockInteractor: MockInteractor!
    
    override func setUp() {
        super.setUp()
        mockInteractor = MockInteractor()
        presenter = WaveformPlaybackPresenter(view: nil, interactor: mockInteractor)
    }
    
    func testDidTapPlayPauseCallsPlayWhenNotPlaying() {
        presenter.state.isPlaying = false
        presenter.didTapPlayPause()
        XCTAssertTrue(mockInteractor.playCalled)
    }
    
    func testDidTapPlayPauseCallsPauseWhenPlaying() {
        presenter.state.isPlaying = true
        presenter.didTapPlayPause()
        XCTAssertTrue(mockInteractor.pauseCalled)
    }
    
    func testDidTapSpeedCallsCycleSpeed() {
        presenter.didTapSpeed()
        XCTAssertTrue(mockInteractor.cycleSpeedCalled)
    }
    
    func testDidSeekCallsSeekTo() {
        presenter.didSeek(to: 45.0)
        XCTAssertEqual(mockInteractor.seekToTime, 45.0, accuracy: 0.1)
    }
}

private final class MockInteractor: WaveformPlaybackInteractorInput {
    var playCalled = false
    var pauseCalled = false
    var seekToTime: TimeInterval = 0
    var cycleSpeedCalled = false
    
    func obtainWaveformData() {}
    func playAudio() { playCalled = true }
    func pauseAudio() { pauseCalled = true }
    func seekTo(_ time: TimeInterval) { seekToTime = time }
    func cycleSpeed() { cycleSpeedCalled = true }
}
