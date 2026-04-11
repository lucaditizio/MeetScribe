import XCTest
@testable import Scribe

final class MindMapInteractorTests: XCTestCase {
    private var interactor: MindMapInteractor!
    private var mockOutput: MockOutput!
    
    override func setUp() {
        mockOutput = MockOutput()
        interactor = MindMapInteractor(output: mockOutput, recordingRepository: MockRepo())
    }
    
    func testObtainMindMapCallsFetch() async {
        let validUUID = UUID()
        interactor.configureWith(recordingId: validUUID.uuidString)
        interactor.obtainMindMap()
        try? await Task.sleep(nanoseconds: 500_000_000)
        XCTAssertTrue(mockOutput.mindMapCalled)
    }
}

private final class MockOutput: MindMapInteractorOutput {
    var mindMapCalled = false
    func didObtainMindMap(nodes: [MindMapNode]) { mindMapCalled = true }
    func didFailWithError(_ error: Error) {}
}

private final class MockRepo: RecordingRepositoryProtocol {
    func fetch(by id: UUID) async throws -> Recording? {
        Recording(id: id, title: "Test", date: Date(), duration: 1.0, fileName: "test", filePath: "/test", source: .rawInternal, meetingNotes: "{\"nodes\":[{\"text\":\"Root\",\"children\":[]}]}")
    }
    func fetchAll() async throws -> [Recording] { [] }
    func delete(_ recording: Recording) async throws {}
    func save(_ recording: Recording) async throws {}
    func update(_ recording: Recording) async throws {}
}
