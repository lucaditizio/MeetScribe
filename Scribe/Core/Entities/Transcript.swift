import Foundation
import SwiftData

/// Represents a complete transcript with speaker-separated segments
@Model
public final class Transcript {
    @Attribute(.unique) public var id: UUID
    public var recordingId: UUID
    public var fullText: String
    public var detectedLanguage: String?
    public var createdAt: Date
    public var updatedAt: Date
    
    @Relationship(deleteRule: .cascade) public var segments: [SpeakerSegment]?
    
    public init(
        id: UUID = UUID(),
        recordingId: UUID,
        fullText: String = "",
        detectedLanguage: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.recordingId = recordingId
        self.fullText = fullText
        self.detectedLanguage = detectedLanguage
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
