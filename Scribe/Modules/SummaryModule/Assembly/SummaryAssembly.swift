import Foundation

public final class SummaryAssembly {
    public static func createModule(recordingId: String) -> SummaryViewInput {
        let interactor = SummaryInteractor(output: nil, recordingRepository: RecordingRepository())
        let presenter = SummaryPresenter(view: nil, interactor: interactor)
        interactor.output = presenter
        return presenter
    }
}
