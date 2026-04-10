import SwiftData
import Foundation

/// Container for SwiftData model configuration
public final class SwiftDataModelContainer {
    public static let shared: ModelContainer = {
        let schema = Schema([
            Recording.self,
            Transcript.self, 
            SpeakerSegment.self,
            MeetingSummary.self,
            TopicSection.self,
            MindMapNode.self
        ])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }()
    
    private init() {}
}
