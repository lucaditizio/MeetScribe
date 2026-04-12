import SwiftUI

/// Top-level assembly and DI composition root.
///
/// `AppAssembly` owns `ServiceRegistry.shared` and delegates all module creation
/// to each module's own Assembly.  It contains zero business logic — only
/// injection of services into Assemblies and wiring of module outputs.
public final class AppAssembly {

    // MARK: - Shared Instance
    public static let shared = AppAssembly()

    // MARK: - Service Registry (single DI root)
    private let services = ServiceRegistry.shared

    // MARK: - Module Factories

    /// RecordingList — the app entry point.
    public func makeRecordingListModule(output: (any ModuleOutput)?) -> some View {
        RecordingListAssembly.build(
            recordingRepository: services.recordingRepository,
            audioRecorder: services.audioRecorder,
            deviceConnectionManager: services.deviceConnectionManager,
            appAssembly: self
        )
    }

    /// RecordingDetail — pushed when the user selects a recording.
    public func makeRecordingDetailModule(recordingId: UUID, output: (any ModuleOutput)?) -> some View {
        let presenter = RecordingDetailAssembly.createModule(
            recordingId: recordingId.uuidString,
            recordingRepository: services.recordingRepository
        )
        return RecordingDetailView(output: presenter)
    }

    /// WaveformPlayback — embedded inside RecordingDetailView.
    public func makeWaveformPlaybackModule(recordingId: UUID, output: (any ModuleOutput)?) -> some View {
        let presenter = WaveformPlaybackAssembly.createModule(
            audioPlayer: services.audioPlayer,
            waveformAnalyzer: WaveformAnalyzer()
        )
        return WaveformPlaybackView(output: presenter)
    }

    /// Transcript tab — embedded inside RecordingDetailView.
    public func makeTranscriptModule(recordingId: UUID, output: (any ModuleOutput)?) -> some View {
        let presenter = TranscriptAssembly.createModule(
            recordingId: recordingId.uuidString,
            recordingRepository: services.recordingRepository
        )
        return TranscriptTabView(output: presenter)
    }

    /// Summary tab — embedded inside RecordingDetailView.
    public func makeSummaryModule(recordingId: UUID, output: (any ModuleOutput)?) -> some View {
        let presenter = SummaryAssembly.createModule(
            recordingId: recordingId.uuidString,
            recordingRepository: services.recordingRepository
        )
        return SummaryTabView(output: presenter)
    }

    /// MindMap tab — embedded inside RecordingDetailView.
    public func makeMindMapModule(recordingId: UUID, output: (any ModuleOutput)?) -> some View {
        let presenter = MindMapAssembly.createModule(
            recordingId: recordingId.uuidString,
            recordingRepository: services.recordingRepository
        )
        return MindMapView(output: presenter)
    }

    /// AgentGenerating — presented as a sheet while a recording is processed.
    public func makeAgentGeneratingModule(recordingId: UUID, output: (any ModuleOutput)?) -> some View {
        let presenter = AgentGeneratingAssembly.createModule(
            recordingId: recordingId.uuidString,
            inferencePipeline: services.inferencePipeline,
            moduleOutput: output as? AgentGeneratingModuleOutput
        )
        if #available(iOS 18.0, *) {
            return AnyView(AgentGeneratingView(presenter: presenter))
        } else {
            return AnyView(
                Text("Processing…")
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black)
                    .preferredColorScheme(.dark)
            )
        }
    }

    /// DeviceSettings — presented as a sheet from the toolbar.
    public func makeDeviceSettingsModule(output: (any ModuleOutput)?) -> some View {
        let presenter = DeviceSettingsAssembly.createModule(
            scanner: services.bluetoothDeviceScanner,
            connectionManager: services.deviceConnectionManager
        )
        return DeviceSettingsView(presenter: presenter)
    }

    // MARK: - Initialization
    private init() {}
}
