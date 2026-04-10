import XCTest
@testable import Scribe

final class RecordingListInteractorTests: XCTestCase {
    private var interactor: RecordingListInteractor!
    private var mockOutput: MockInteractorOutput!
    private var mockRepository: MockRecordingRepositoryForTests!
    
    override func setUp() {
        super.setUp()
        mockOutput = MockInteractorOutput()
        mockRepository = MockRecordingRepositoryForTests()
        interactor = RecordingListInteractor(
            output: mockOutput,
            recordingRepository: mockRepository
        )
    }
    
    func testObtainRecordingsCallsFetchAll() async {
        interactor.obtainRecordings()
        await Task.yield()
        XCTAssertTrue(mockRepository.fetchAllCalled)
    }
    
    func testDeleteRecordingCallsDelete() async {
        let validUUID = UUID().uuidString
        interactor.deleteRecording(id: validUUID)
        await Task.yield()
        XCTAssertTrue(mockRepository.deleteCalled)
    }
}

private final class MockInteractorOutput: RecordingListInteractorOutput {
    var recordings: [Recording] = []
    func didObtainRecordings(_ recordings: [Recording]) {
        self.recordings = recordings
    }
    func didFailWithError(_ error: Error) {}
}

private final class MockRecordingRepositoryForTests: RecordingRepositoryProtocol {
    var fetchAllCalled = false
    var deleteCalled = false
    
    func fetchAll() async throws -> [Recording] {
        fetchAllCalled = true
        return []
    }
    
    func delete(_ recording: Recording) async throws {
        deleteCalled = true
    }
    
    func save(_ recording: Recording) async throws {}
    func fetch(by id: UUID) async throws -> Recording? {
        return Recording(
            id: id,
            title: "Test",
            date: Date(),
            duration: 1.0,
            fileName: "test.caf",
            filePath: "/test/test.caf",
            source: .rawInternal
        )
    }
}
