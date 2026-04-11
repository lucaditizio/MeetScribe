import Foundation

public final class TranscriptAssembly {
    public static func createModule(recordingId: String) -> TranscriptViewInput {
        // Create output (Presenter)
        let presenter = TranscriptPresenter(
            view: nil,
            interactor: TranscriptInteractor(
                output: nil,
                recordingRepository: ServiceRegistry.shared.recordingRepository
            )
        )
        
        // Create interactor with RecordingRepositoryProtocol
        let interactor = TranscriptInteractor(
            output: presenter,
            recordingRepository: ServiceRegistry.shared.recordingRepository
        )
        
        // Configure interactor with recordingId
        interactor.configureWith(recordingId: recordingId)
        
        // Wire together and return view
        presenter.view = nil // View will be set by caller
        return TranscriptViewMock(presenter: presenter)
    }
}

// MARK: - Mock for testing
class TranscriptViewMock: TranscriptViewInput {
    private let presenter: TranscriptPresenter
    
    init(presenter: TranscriptPresenter) {
        self.presenter = presenter
    }
    
    func displayTranscriptSegments(_ segments: [SpeakerSegment]) {
        presenter.state.segments = segments
    }
    
    func displayError(_ error: Error) {
        presenter.state.isLoading = false
    }
}
