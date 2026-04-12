import Foundation

/// Assembly for MindMapModule.
/// Accepts a shared RecordingRepositoryProtocol from AppAssembly so the module
/// shares the same data source as the rest of the app.
public final class MindMapAssembly {

    public static func createModule(
        recordingId: String,
        recordingRepository: RecordingRepositoryProtocol
    ) -> MindMapPresenter {
        let interactor = MindMapInteractor(
            output: nil,
            recordingRepository: recordingRepository
        )
        interactor.configureWith(recordingId: recordingId)

        let presenter = MindMapPresenter(view: nil, interactor: interactor)
        interactor.output = presenter

        return presenter
    }
}
