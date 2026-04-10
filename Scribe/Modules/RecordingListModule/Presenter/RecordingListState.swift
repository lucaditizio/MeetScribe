import Foundation

/// Plain state object for RecordingList module
public struct RecordingListState: Equatable {
    public var recordings: [Recording]
    public var isRecording: Bool
    public var micSource: String
    public var isLoading: Bool
    
    public init(
        recordings: [Recording] = [],
        isRecording: Bool = false,
        micSource: String = "internal",
        isLoading: Bool = false
    ) {
        self.recordings = recordings
        self.isRecording = isRecording
        self.micSource = micSource
        self.isLoading = isLoading
    }
}
