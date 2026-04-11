import Foundation

public struct SummaryTopicSection: Equatable, Identifiable {
    public var id: UUID
    public var title: String
    public var content: String
    
    public init(id: UUID = UUID(), title: String, content: String) {
        self.id = id
        self.title = title
        self.content = content
    }
}

public struct SummaryState: Equatable {
    public var topicSections: [SummaryTopicSection]
    public var actionItems: [String]
    public var isLoading: Bool
    
    public init(
        topicSections: [SummaryTopicSection] = [],
        actionItems: [String] = [],
        isLoading: Bool = false
    ) {
        self.topicSections = topicSections
        self.actionItems = actionItems
        self.isLoading = isLoading
    }
}
