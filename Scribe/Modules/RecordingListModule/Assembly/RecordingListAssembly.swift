import Foundation

/// Assembly for RecordingListModule.
///
/// Builds the full VIPER stack (Router → Interactor → Presenter → View) and
/// returns the wired root view.  AppAssembly never touches the internals —
/// it just receives a ready-to-display view.
public final class RecordingListAssembly {

    /// Builds and returns the fully wired RecordingListView.
    /// - Parameters:
    ///   - recordingRepository: Shared repository injected from ServiceRegistry.
    ///   - appAssembly: AppAssembly passed to the Router so it can build
    ///     destination views during navigation without holding services itself.
    public static func build(
        recordingRepository: RecordingRepositoryProtocol,
        appAssembly: AppAssembly
    ) -> RecordingListView {
        let router = RecordingListRouter(appAssembly: appAssembly)

        let interactor = RecordingListInteractor(
            output: nil,
            recordingRepository: recordingRepository
        )

        let presenter = RecordingListPresenter(
            view: nil,
            interactor: interactor,
            router: router
        )

        return RecordingListView(output: presenter, router: router)
    }
}
