import Foundation
import SwiftData

public final class RecordingRepository: RecordingRepositoryProtocol {
    private let modelContainer: ModelContainer
    
    public init(modelContainer: ModelContainer = SwiftDataModelContainer.shared) {
        self.modelContainer = modelContainer
    }
    
    public func save(_ recording: Recording) async throws {
        let context = ModelContext(modelContainer)
        context.insert(recording)
        try context.save()
        ScribeLogger.info("Recording saved: \(recording.id)", category: .audio)
    }
    
    public func fetchAll() async throws -> [Recording] {
        let context = ModelContext(modelContainer)
        let descriptor = FetchDescriptor<Recording>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
        return try context.fetch(descriptor)
    }
    
    public func fetch(by id: UUID) async throws -> Recording? {
        let context = ModelContext(modelContainer)
        let descriptor = FetchDescriptor<Recording>(predicate: #Predicate { $0.id == id })
        return try context.fetch(descriptor).first
    }
    
    public func delete(_ recording: Recording) async throws {
        let context = ModelContext(modelContainer)
        // Fetch the recording in this context before deleting
        let recordingId = recording.id
        let descriptor = FetchDescriptor<Recording>(predicate: #Predicate { recording in
            recording.id == recordingId
        })
        guard let recordingToDelete = try context.fetch(descriptor).first else {
            ScribeLogger.warning("Recording not found for deletion: \(recording.id)", category: .audio)
            return
        }
        context.delete(recordingToDelete)
        try context.save()
        ScribeLogger.info("Recording deleted: \(recording.id)", category: .audio)
    }
}
