import Foundation

/// Assembly for TranscriptModule.
/// Accepts a shared RecordingRepositoryProtocol injected from AppAssembly.
public final class TranscriptAssembly {

    public static func createModule(
        recordingId: String,
        recordingRepository: RecordingRepositoryProtocol
    ) -> TranscriptPresenter {
        let interactor = TranscriptInteractor(
            output: nil,
            recordingRepository: recordingRepository
        )
        interactor.configureWith(recordingId: recordingId)

        let presenter = TranscriptPresenter(view: nil, interactor: interactor)
        return presenter
    }
}
