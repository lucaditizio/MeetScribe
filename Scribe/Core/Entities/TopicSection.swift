import Foundation
import SwiftData

/// Represents a single topic/section within a meeting summary
@Model
public final class TopicSection {
    public var id: UUID
    public var topic: String
    public var bullets: [String]
    public var order: Int
    public var createdAt: Date
    
    public init(
        id: UUID = UUID(),
        topic: String,
        bullets: [String],
        order: Int,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.topic = topic
        self.bullets = bullets
        self.order = order
        self.createdAt = createdAt
    }
}
