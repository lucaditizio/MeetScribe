import Foundation
import SwiftData

/// Represents a single segment of speech from a specific speaker
@Model
public final class SpeakerSegment {
    public var id: UUID
    public var speakerId: Int
    public var speakerName: String
    public var startTime: TimeInterval
    public var endTime: TimeInterval
    public var text: String
    public var confidence: Double
    public var createdAt: Date
    
    public init(
        id: UUID = UUID(),
        speakerId: Int,
        speakerName: String,
        startTime: TimeInterval,
        endTime: TimeInterval,
        text: String,
        confidence: Double = 1.0,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.speakerId = speakerId
        self.speakerName = speakerName
        self.startTime = startTime
        self.endTime = endTime
        self.text = text
        self.confidence = confidence
        self.createdAt = createdAt
    }
}
