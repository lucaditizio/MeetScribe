import Foundation

/// Assembly for SummaryModule.
/// Accepts a shared RecordingRepositoryProtocol from AppAssembly so the module
/// shares the same data source as the rest of the app.
public final class SummaryAssembly {

    public static func createModule(
        recordingId: String,
        recordingRepository: RecordingRepositoryProtocol
    ) -> SummaryPresenter {
        let interactor = SummaryInteractor(
            output: nil,
            recordingRepository: recordingRepository
        )
        interactor.configureWith(recordingId: recordingId)

        let presenter = SummaryPresenter(view: nil, interactor: interactor)
        interactor.output = presenter

        return presenter
    }
}
