import Foundation

public enum RecordingDetailTab: Equatable {
    case summary
    case transcript
    case mindMap
}

public struct RecordingDetailState: Equatable {
    public var recording: Recording?
    public var selectedTab: RecordingDetailTab
    public var isProcessing: Bool
    
    public init(
        recording: Recording? = nil,
        selectedTab: RecordingDetailTab = .summary,
        isProcessing: Bool = false
    ) {
        self.recording = recording
        self.selectedTab = selectedTab
        self.isProcessing = isProcessing
    }
}
