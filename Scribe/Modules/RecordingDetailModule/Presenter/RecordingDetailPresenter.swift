import Foundation

@Observable
public final class RecordingDetailPresenter: RecordingDetailViewOutput {
    public var state = RecordingDetailState()
    private weak var view: RecordingDetailViewInput?
    private let interactor: RecordingDetailInteractorInput
    private let router: RecordingDetailRouterInput
    
    public init(
        view: RecordingDetailViewInput?,
        interactor: RecordingDetailInteractorInput,
        router: RecordingDetailRouterInput
    ) {
        self.view = view
        self.interactor = interactor
        self.router = router
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
}
