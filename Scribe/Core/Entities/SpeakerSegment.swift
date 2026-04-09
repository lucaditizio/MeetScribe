import Foundation
import SwiftData

/// Represents a single segment of speech from a specific speaker
@Model
public final class SpeakerSegment {
    public var id: UUID
    public var speakerId: String
    public var speakerName: String
    public var start: TimeInterval
    public var end: TimeInterval
    public var text: String
    public var confidence: Double
    public var createdAt: Date
    
    public init(
        id: UUID = UUID(),
        speakerId: String,
        speakerName: String,
        start: TimeInterval,
        end: TimeInterval,
        text: String,
        confidence: Double = 1.0,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.speakerId = speakerId
        self.speakerName = speakerName
        self.start = start
        self.end = end
        self.text = text
        self.confidence = confidence
        self.createdAt = createdAt
    }
}
