import Foundation

@Observable
public final class WaveformPlaybackPresenter: WaveformPlaybackViewOutput, WaveformPlaybackModuleInput, WaveformPlaybackInteractorOutput {
    public var state = WaveformPlaybackState()
    private weak var view: WaveformPlaybackViewInput?
    private let interactor: WaveformPlaybackInteractorInput
    
    public init(
        view: WaveformPlaybackViewInput?,
        interactor: WaveformPlaybackInteractorInput
    ) {
        self.view = view
        self.interactor = interactor
    }
    
    public func configureWith(recordingId: String) {
        interactor.configureWith(recordingId: recordingId)
    }
    
    public func didTriggerViewReady() {
        interactor.obtainWaveformData()
    }
    
    public func didTapPlayPause() {
        if state.isPlaying {
            interactor.pauseAudio()
        } else {
            interactor.playAudio()
        }
    }
    
    public func didTapSkipForward() {
        let newTime = min(state.currentTime + 15, state.duration)
        interactor.seekTo(newTime)
    }
    
    public func didTapSkipBackward() {
        let newTime = max(state.currentTime - 15, 0)
        interactor.seekTo(newTime)
    }
    
    public func didSeek(to time: TimeInterval) {
        interactor.seekTo(time)
    }
    
    public func didTapSpeed() {
        interactor.cycleSpeed()
    }
    
    public func pausePlayback() {
        interactor.pauseAudio()
    }
    
    // MARK: - WaveformPlaybackInteractorOutput
    
    public func didObtainWaveformData(_ bars: [Float]) {
        state.waveformBars = bars
    }
    
    public func didUpdatePlaybackState(isPlaying: Bool, currentTime: TimeInterval) {
        state.isPlaying = isPlaying
        state.currentTime = currentTime
    }
    
    public func didUpdateDuration(_ duration: TimeInterval) {
        state.duration = duration
    }
    
    public func didUpdateSpeed(_ speed: Float) {
        state.speed = speed
    }
    
    public func didFailWithError(_ error: Error) {
        print("WaveformPlayback error: \(error)")
    }
}
