import SwiftUI

/// Assembly that wires all services and creates module instances
public final class AppAssembly {
    
    // MARK: - Shared Instance
    public static let shared = AppAssembly()
    
    // MARK: - Service Registry
    private let services = ServiceRegistry.shared
    
    // MARK: - Module Factories (placeholder Views for now)
    
    public func makeRecordingListModule(output: (any ModuleOutput)?) -> some View {
        Text("RecordingListModule - Placeholder")
            .preferredColorScheme(.dark)
    }
    
    public func makeRecordingDetailModule(recordingId: UUID, output: (any ModuleOutput)?) -> some View {
        Text("RecordingDetailModule - Placeholder")
            .preferredColorScheme(.dark)
    }
    
    public func makeWaveformPlaybackModule(recordingId: UUID, output: (any ModuleOutput)?) -> some View {
        Text("WaveformPlaybackModule - Placeholder")
            .preferredColorScheme(.dark)
    }
    
    public func makeTranscriptModule(recordingId: UUID, output: (any ModuleOutput)?) -> some View {
        Text("TranscriptModule - Placeholder")
            .preferredColorScheme(.dark)
    }
    
    public func makeSummaryModule(recordingId: UUID, output: (any ModuleOutput)?) -> some View {
        Text("SummaryModule - Placeholder")
            .preferredColorScheme(.dark)
    }
    
    public func makeMindMapModule(recordingId: UUID, output: (any ModuleOutput)?) -> some View {
        Text("MindMapModule - Placeholder")
            .preferredColorScheme(.dark)
    }
    
    public func makeAgentGeneratingModule(recordingId: UUID, output: (any ModuleOutput)?) -> some View {
        Text("AgentGeneratingModule - Placeholder")
            .preferredColorScheme(.dark)
    }
    
    public func makeDeviceSettingsModule(output: (any ModuleOutput)?) -> some View {
        Text("DeviceSettingsModule - Placeholder")
            .preferredColorScheme(.dark)
    }
    
    // MARK: - Initialization
    private init() {}
}
