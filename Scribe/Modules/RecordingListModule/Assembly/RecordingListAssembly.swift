import Foundation

/// Assembly for RecordingListModule.
///
/// Builds the full VIPER stack (Router → Interactor → Presenter → View) and
/// returns the wired root view.  AppAssembly never touches the internals —
/// it just receives a ready-to-display view.
public final class RecordingListAssembly {

    public static func build(
        recordingRepository: RecordingRepositoryProtocol,
        audioRecorder: AudioRecorderProtocol,
        appAssembly: AppAssembly
    ) -> RecordingListView {
        let router = RecordingListRouter(appAssembly: appAssembly)

        let interactor = RecordingListInteractor(
            output: nil,
            recordingRepository: recordingRepository,
            audioRecorder: audioRecorder
        )

        let presenter = RecordingListPresenter(
            view: nil,
            interactor: interactor,
            router: router
        )

        return RecordingListView(output: presenter, router: router)
    }
}
