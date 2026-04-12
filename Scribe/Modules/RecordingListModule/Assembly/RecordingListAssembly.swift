import Foundation
import SwiftData

public final class RecordingListAssembly {

    public static func build(
        recordingRepository: RecordingRepositoryProtocol,
        audioRecorder: AudioRecorderProtocol,
        deviceConnectionManager: DeviceConnectionManagerProtocol,
        appAssembly: AppAssembly
    ) -> RecordingListView {
        let router = RecordingListRouter(appAssembly: appAssembly)

        let interactor = RecordingListInteractor(
            output: nil,
            recordingRepository: recordingRepository,
            audioRecorder: audioRecorder,
            deviceConnectionManager: deviceConnectionManager
        )

        let presenter = RecordingListPresenter(
            view: nil,
            interactor: interactor,
            router: router
        )

        return RecordingListView(presenter: presenter, router: router)
    }
}
