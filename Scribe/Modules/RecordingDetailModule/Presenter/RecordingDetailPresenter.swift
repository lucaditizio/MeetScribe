import Foundation

@Observable
public final class RecordingDetailPresenter: RecordingDetailViewOutput {
    public var state = RecordingDetailState()
    public var waveformPresenter: WaveformPlaybackPresenter?
    private weak var view: RecordingDetailViewInput?
    private let interactor: RecordingDetailInteractorInput
    private let router: RecordingDetailRouterInput
    
    public init(
        view: RecordingDetailViewInput?,
        interactor: RecordingDetailInteractorInput,
        router: RecordingDetailRouterInput,
        waveformPresenter: WaveformPlaybackPresenter? = nil
    ) {
        self.view = view
        self.interactor = interactor
        self.router = router
        self.waveformPresenter = waveformPresenter
    }
    
    public func didTriggerViewReady() {}
    
    public func didSelectTab(_ tab: RecordingDetailTab) {
        state.selectedTab = tab
    }
    
    public func didTapGenerateTranscript() {
        state.isProcessing = true
    }
    
    public func didTapPlayPause() {}
    
    public func didTapSkipForward() {}
    
    public func didTapSkipBackward() {}
    
    public func didExitRecordingDetail() {
        waveformPresenter?.interactor?.pauseAudio()
    }
}
