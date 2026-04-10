import Foundation

public final class RecordingDetailAssembly {
    public static func createModule(recordingId: String) -> RecordingDetailViewInput {
        let recordingRepository = RecordingRepository()
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
        
        interactor.obtainRecording(id: recordingId)
        
        return presenter as! RecordingDetailViewInput
    }
}
