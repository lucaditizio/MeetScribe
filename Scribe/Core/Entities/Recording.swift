import Foundation
import SwiftData

/// Represents a recorded meeting with metadata
@Model
public final class Recording {
    @Attribute(.unique) public var id: UUID
    public var title: String
    public var date: Date
    public var duration: TimeInterval
    public var fileName: String
    public var filePath: String
    public var source: RecordingSource
    public var createdAt: Date
    public var updatedAt: Date
    
    public var rawTranscript: String
    public var actionItems: String?
    public var meetingNotes: String?
    
    @Relationship(deleteRule: .cascade) public var transcript: Transcript?
    
    public init(
        id: UUID = UUID(),
        title: String,
        date: Date,
        duration: TimeInterval = 0,
        fileName: String,
        filePath: String,
        source: RecordingSource = .rawInternal,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        rawTranscript: String = "",
        actionItems: String? = nil,
        meetingNotes: String? = nil,
        transcript: Transcript? = nil
    ) {
        self.id = id
        self.title = title
        self.date = date
        self.duration = duration
        self.fileName = fileName
        self.filePath = filePath
        self.source = source
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.rawTranscript = rawTranscript
        self.actionItems = actionItems
        self.meetingNotes = meetingNotes
        self.transcript = transcript
    }
}
