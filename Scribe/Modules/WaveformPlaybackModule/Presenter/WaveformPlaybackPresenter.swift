import Foundation

@Observable
public final class WaveformPlaybackPresenter: WaveformPlaybackViewOutput {
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
}
