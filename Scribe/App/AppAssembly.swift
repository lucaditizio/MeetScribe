import SwiftUI

/// Top-level assembly that wires real module instances.
/// `ServiceRegistry.shared` is the single DI root — each module factory
/// injects the service instances it needs via its Interactor.
public final class AppAssembly {

    // MARK: - Shared Instance
    public static let shared = AppAssembly()

    // MARK: - Service Registry
    private let services = ServiceRegistry.shared

    // MARK: - Module Factories

    /// Returns the RecordingList module root view, fully wired with real services.
    public func makeRecordingListModule(output: (any ModuleOutput)?) -> some View {
        // Build VIPER stack manually so real services flow through DI
        let router = RecordingListRouter(viewController: nil)

        // Presenter is created first; interactor references it as output
        let presenter = RecordingListPresenter(
            view: nil,
            interactor: RecordingListInteractor(
                output: nil,
                recordingRepository: services.recordingRepository
            ),
            router: router
        )

        return RecordingListView(output: presenter)
    }

    public func makeRecordingDetailModule(recordingId: UUID, output: (any ModuleOutput)?) -> some View {
        Text("RecordingDetailModule — coming soon")
            .preferredColorScheme(.dark)
    }

    public func makeWaveformPlaybackModule(recordingId: UUID, output: (any ModuleOutput)?) -> some View {
        Text("WaveformPlaybackModule — coming soon")
            .preferredColorScheme(.dark)
    }

    public func makeTranscriptModule(recordingId: UUID, output: (any ModuleOutput)?) -> some View {
        Text("TranscriptModule — coming soon")
            .preferredColorScheme(.dark)
    }

    public func makeSummaryModule(recordingId: UUID, output: (any ModuleOutput)?) -> some View {
        Text("SummaryModule — coming soon")
            .preferredColorScheme(.dark)
    }

    public func makeMindMapModule(recordingId: UUID, output: (any ModuleOutput)?) -> some View {
        Text("MindMapModule — coming soon")
            .preferredColorScheme(.dark)
    }

    public func makeAgentGeneratingModule(recordingId: UUID, output: (any ModuleOutput)?) -> some View {
        Text("AgentGeneratingModule — coming soon")
            .preferredColorScheme(.dark)
    }

    public func makeDeviceSettingsModule(output: (any ModuleOutput)?) -> some View {
        Text("DeviceSettingsModule — coming soon")
            .preferredColorScheme(.dark)
    }

    // MARK: - Initialization
    private init() {}
}
