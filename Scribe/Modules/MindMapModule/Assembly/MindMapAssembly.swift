import Foundation

public final class MindMapAssembly {
    public static func createModule(recordingId: String) -> MindMapViewInput {
        let interactor = MindMapInteractor(output: nil, recordingRepository: RecordingRepository())
        let presenter = MindMapPresenter(view: nil, interactor: interactor)
        interactor.output = presenter
        return presenter
    }
}
