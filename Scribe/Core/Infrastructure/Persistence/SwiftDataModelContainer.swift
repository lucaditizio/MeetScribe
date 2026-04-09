import SwiftData
import Foundation

/// Container for SwiftData model configuration
/// Provides on-disk persistence for Recording entities
final class SwiftDataModelContainer {
    static let shared: ModelContainer = {
        let schema = Schema([])  // Empty schema for now, will add Recording entity later
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }()
    
    private init() {}
}
