import Foundation
import SwiftData

public struct TranscriptState {
    public var segments: [SpeakerSegment]
    public var selectedSpeakerForRename: String?
    public var isLoading: Bool
    
    public init(
        segments: [SpeakerSegment] = [],
        selectedSpeakerForRename: String? = nil,
        isLoading: Bool = false
    ) {
        self.segments = segments
        self.selectedSpeakerForRename = selectedSpeakerForRename
        self.isLoading = isLoading
    }
}
