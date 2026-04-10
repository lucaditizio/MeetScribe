import XCTest
import SwiftData
@testable import Scribe

final class RecordingRepositoryTests: XCTestCase {
    private var repository: RecordingRepository!
    private var modelContainer: ModelContainer!
    
    override func setUp() async throws {
        try await super.setUp()
        let schema = Schema([Recording.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        modelContainer = try ModelContainer(for: schema, configurations: [config])
        repository = RecordingRepository(modelContainer: modelContainer)
    }
    
    override func tearDown() {
        repository = nil
        modelContainer = nil
        super.tearDown()
    }
    
    private func createTestRecording() -> Recording {
        return Recording(
            title: "Test Recording",
            date: Date(),
            duration: 60.0,
            fileName: "test.caf",
            filePath: "/test/path/test.caf",
            source: .rawInternal
        )
    }
    
    func testSaveRecording() async throws {
        let recording = createTestRecording()
        try await repository.save(recording)
        
        let fetched = try await repository.fetch(by: recording.id)
        XCTAssertNotNil(fetched, "Recording should be saved and retrievable")
        XCTAssertEqual(fetched?.title, recording.title, "Title should match")
        XCTAssertEqual(fetched?.duration, recording.duration, "Duration should match")
    }
    
    func testFetchAll() async throws {
        let recording1 = createTestRecording()
        let recording2 = createTestRecording()
        let recording3 = createTestRecording()
        
        try await repository.save(recording1)
        try await repository.save(recording2)
        try await repository.save(recording3)
        
        let allRecordings = try await repository.fetchAll()
        XCTAssertEqual(allRecordings.count, 3, "Should fetch all 3 recordings")
        
        let ids = allRecordings.map { $0.id }
        XCTAssertTrue(ids.contains(recording1.id), "Should contain recording1")
        XCTAssertTrue(ids.contains(recording2.id), "Should contain recording2")
        XCTAssertTrue(ids.contains(recording3.id), "Should contain recording3")
    }
    
    func testFetchById() async throws {
        let recording = createTestRecording()
        try await repository.save(recording)
        
        let fetched = try await repository.fetch(by: recording.id)
        XCTAssertNotNil(fetched, "Recording should be found by ID")
        XCTAssertEqual(fetched?.id, recording.id, "ID should match")
        XCTAssertEqual(fetched?.title, recording.title, "Title should match")
        
        let nonExistentId = UUID()
        let notFound = try await repository.fetch(by: nonExistentId)
        XCTAssertNil(notFound, "Non-existent recording should return nil")
    }
    
    func testDeleteRecording() async throws {
        let recording = createTestRecording()
        try await repository.save(recording)
        
        try await repository.delete(recording)
        
        let fetched = try await repository.fetch(by: recording.id)
        XCTAssertNil(fetched, "Deleted recording should not be found")
        
        let allRecordings = try await repository.fetchAll()
        XCTAssertEqual(allRecordings.count, 0, "No recordings should remain")
        
        let newRecording = createTestRecording()
        try await repository.save(newRecording)
        let recordingsAfterSave = try await repository.fetchAll()
        XCTAssertEqual(recordingsAfterSave.count, 1, "Should have exactly 1 recording after save")
    }
}
