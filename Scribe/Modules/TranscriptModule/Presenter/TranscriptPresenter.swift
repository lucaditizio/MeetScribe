import Foundation
import SwiftUI

@Observable
public final class TranscriptPresenter: TranscriptModuleInput, TranscriptViewOutput {
    private weak var view: TranscriptViewInput?
    private let interactor: TranscriptInteractorInput
    public var state: TranscriptState
    
    public init(view: TranscriptViewInput?, interactor: TranscriptInteractorInput) {
        self.view = view
        self.interactor = interactor
        self.state = TranscriptState()
    }
    
    public func configureWith(recordingId: String) {}
    
    public func didTriggerViewReady() {
        state.isLoading = true
        interactor.obtainTranscriptSegments()
    }
    
    public func didTapSpeaker(speakerId: String) {
        state.selectedSpeakerForRename = speakerId
    }
    
    public func didConfirmRename() {
        guard let speakerId = state.selectedSpeakerForRename else { return }
    }
    
    public func didCancelRename() {
        state.selectedSpeakerForRename = nil
    }
}
