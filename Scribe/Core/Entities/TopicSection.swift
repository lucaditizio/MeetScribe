import Foundation
import SwiftData

/// Represents a single topic/section within a meeting summary
@Model
public final class TopicSection {
    public var id: UUID
    public var title: String
    public var content: String
    public var order: Int
    public var createdAt: Date
    
    public init(
        id: UUID = UUID(),
        title: String,
        content: String,
        order: Int,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.content = content
        self.order = order
        self.createdAt = createdAt
    }
}
