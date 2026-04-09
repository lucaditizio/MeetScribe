import Foundation
import SwiftData

/// Represents an AI-generated summary of a meeting
@Model
public final class MeetingSummary {
    @Attribute(.unique) public var id: UUID
    public var recordingId: UUID
    public var overview: String
    public var keyPoints: [String]
    public var actionItems: [String]
    public var createdAt: Date
    public var updatedAt: Date
    
    @Relationship(deleteRule: .cascade) public var topics: [TopicSection]?
    
    public init(
        id: UUID = UUID(),
        recordingId: UUID,
        overview: String = "",
        keyPoints: [String] = [],
        actionItems: [String] = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.recordingId = recordingId
        self.overview = overview
        self.keyPoints = keyPoints
        self.actionItems = actionItems
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
