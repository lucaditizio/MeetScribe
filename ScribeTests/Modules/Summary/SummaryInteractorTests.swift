import XCTest
@testable import Scribe

final class SummaryInteractorTests: XCTestCase {
    private var interactor: SummaryInteractor!
    private var mockOutput: MockOutput!
    
    override func setUp() {
        mockOutput = MockOutput()
        interactor = SummaryInteractor(output: mockOutput, recordingRepository: MockRepo())
    }
    
    func testObtainSummaryCallsFetch() async {
        interactor.configureWith(recordingId: UUID().uuidString)
        interactor.obtainSummary()
        try? await Task.sleep(nanoseconds: 100_000_000)
        XCTAssertTrue(mockOutput.summaryCalled)
    }
}

private final class MockOutput: SummaryInteractorOutput {
    var summaryCalled = false
    func didObtainSummary(topicSections: [SummaryTopicSection], actionItems: [String]) { summaryCalled = true }
    func didFailWithError(_ error: Error) {}
}

private final class MockRepo: RecordingRepositoryProtocol {
    func fetch(by id: UUID) async throws -> Recording? {
        Recording(id: id, title: "Test", date: Date(), duration: 1.0, fileName: "test", filePath: "/test", source: .rawInternal, createdAt: Date(), updatedAt: Date(), rawTranscript: "", actionItems: "Item 1\nItem 2", meetingNotes: "Section 1\nContent")
    }
    func fetchAll() async throws -> [Recording] { [] }
    func delete(_ recording: Recording) async throws {}
    func save(_ recording: Recording) async throws {}
    func update(_ recording: Recording) async throws {}
}
