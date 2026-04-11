import Foundation

@Observable
public final class TranscriptPresenter: TranscriptViewOutput {
    public var state = TranscriptState()
    private weak var view: TranscriptViewInput?
    private let interactor: TranscriptInteractorInput
    
    public init(
        view: TranscriptViewInput?,
        interactor: TranscriptInteractorInput
    ) {
        self.view = view
        self.interactor = interactor
    }
    
    // TranscriptViewOutput
    public func didTriggerViewReady() {
        state.isLoading = true
        interactor.obtainTranscriptSegments()
    }
    
    public func didTapSpeaker(speakerId: String) {
        state.selectedSpeakerForRename = speakerId
    }
}
