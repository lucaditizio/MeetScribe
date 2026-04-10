import Foundation

public final class RecordingListAssembly {
    public static func createModule() -> RecordingListViewInput {
        let recordingRepository = RecordingRepository()
        let interactor = RecordingListInteractor(
            output: nil,
            recordingRepository: recordingRepository
        )
        let router = RecordingListRouter(viewController: nil)
        let presenter = RecordingListPresenter(
            view: nil,
            interactor: interactor,
            router: router
        )
        
        return presenter
    }
}
