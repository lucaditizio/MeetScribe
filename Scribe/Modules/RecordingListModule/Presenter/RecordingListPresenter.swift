import Foundation
import SwiftData

@Observable
public final class RecordingListPresenter: RecordingListViewOutput, RecordingListViewInput, RecordingListInteractorOutput {
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
        if state.isRecording {
            interactor.stopRecording()
        } else {
            interactor.startRecording()
        }
    }
    
    public func didTapRecording(id: String) {
        guard let recording = state.recordings.first(where: { $0.id.uuidString == id }) else { return }
        router.openRecordingDetail(with: recording)
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
    
    public func didStartRecording() {
        state.isRecording = true
    }
    
    public func didStopRecording(result: Recording?) {
        state.isRecording = false
        if result != nil {
            interactor.obtainRecordings()
        }
    }
    
    public func didObtainRecordings(_ recordings: [Recording]) {
        state.recordings = recordings
        state.isLoading = false
        view?.displayRecordings(recordings)
    }
    
    public func didFailWithError(_ error: Error) {
        state.isLoading = false
        state.isRecording = false
        view?.displayError(error)
    }
}
