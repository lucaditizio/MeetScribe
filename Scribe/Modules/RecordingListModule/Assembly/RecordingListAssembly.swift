import Foundation
import SwiftData

public final class RecordingListAssembly {

    public static func build(
        recordingRepository: RecordingRepositoryProtocol,
        audioRecorder: AudioRecorderProtocol,
        audioConverter: AudioConverter,
        deviceConnectionManager: DeviceConnectionManagerProtocol,
        appAssembly: AppAssembly
    ) -> RecordingListView {
        let router = RecordingListRouter(appAssembly: appAssembly)
        
        let presenter = RecordingListPresenter(
            view: nil,
            interactor: nil,
            router: router
        )
        
        let interactor = RecordingListInteractor(
            output: presenter,
            recordingRepository: recordingRepository,
            audioRecorder: audioRecorder,
            audioConverter: audioConverter,
            deviceConnectionManager: deviceConnectionManager
        )
        
        presenter.interactor = interactor
        
        return RecordingListView(presenter: presenter, router: router)
    }
}
