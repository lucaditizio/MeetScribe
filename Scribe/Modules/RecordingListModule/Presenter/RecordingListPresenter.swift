import Foundation

@Observable
public final class RecordingListPresenter: RecordingListViewOutput, RecordingListViewInput {
    public var state = RecordingListState()
    private weak var view: RecordingListViewInput?
    private let interactor: RecordingListInteractorInput
    private let router: RecordingListRouterInput
    
    public init(
        view: RecordingListViewInput?,
        interactor: RecordingListInteractorInput,
        router: RecordingListRouterInput
    ) {
        self.view = view
        self.interactor = interactor
        self.router = router
    }
    
    public func didTriggerViewReady() {
        interactor.obtainRecordings()
    }
    
    public func didTapRecord() {
        router.openAgentGenerating()
    }
    
    public func didTapRecording(id: String) {
        // Navigation handled by router
    }
    
    public func didTapSettings() {
        router.openDeviceSettings()
    }
    
    public func didDeleteRecording(id: String) {
        interactor.deleteRecording(id: id)
    }
    
    public func displayRecordings(_ recordings: [Recording]) {
        state.recordings = recordings
        state.isLoading = false
        view?.displayRecordings(recordings)
    }
    
    public func displayError(_ error: Error) {
        state.isLoading = false
        view?.displayError(error)
    }
}
