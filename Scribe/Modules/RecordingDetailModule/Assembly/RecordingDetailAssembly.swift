import Foundation

/// Assembly for RecordingDetailModule.
/// Accepts a shared RecordingRepositoryProtocol injected from AppAssembly.
public final class RecordingDetailAssembly {

    public static func createModule(
        recordingId: String,
        recordingRepository: RecordingRepositoryProtocol
    ) -> RecordingDetailPresenter {
        let interactor = RecordingDetailInteractor(
            output: nil,
            recordingRepository: recordingRepository
        )
        let router = RecordingDetailRouter(viewController: nil)
        let presenter = RecordingDetailPresenter(
            view: nil,
            interactor: interactor,
            router: router
        )

        // Kick off initial data load
        interactor.obtainRecording(id: recordingId)

        return presenter
    }
}
