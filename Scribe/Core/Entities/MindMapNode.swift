import Foundation
import SwiftData

/// Represents a node in the AI-generated mind map
@Model
public final class MindMapNode {
    @Attribute(.unique) public var id: UUID
    public var summaryId: UUID
    public var parentId: UUID?
    public var text: String
    public var order: Int
    public var level: Int
    public var createdAt: Date
    
    @Relationship(deleteRule: .cascade) public var children: [MindMapNode]?
    
    public init(
        id: UUID = UUID(),
        summaryId: UUID,
        parentId: UUID? = nil,
        text: String,
        order: Int,
        level: Int,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.summaryId = summaryId
        self.parentId = parentId
        self.text = text
        self.order = order
        self.level = level
        self.createdAt = createdAt
    }
}
