import XCTest
@testable import Scribe

final class RecordingDetailInteractorTests: XCTestCase {
    private var interactor: RecordingDetailInteractor!
    private var mockOutput: MockInteractorOutput!
    private var mockRepository: MockRecordingRepositoryForTests!
    
    override func setUp() {
        super.setUp()
        mockOutput = MockInteractorOutput()
        mockRepository = MockRecordingRepositoryForTests()
        interactor = RecordingDetailInteractor(output: mockOutput, recordingRepository: mockRepository)
    }
    
    func testObtainRecordingCallsFetchById() async {
        interactor.obtainRecording(id: "test-id")
        try? await Task.sleep(nanoseconds: 100_000_000)
        XCTAssertTrue(mockRepository.fetchByIdCalled)
    }
}

private final class MockInteractorOutput: RecordingDetailInteractorOutput {
    var recording: Recording?
    func didObtainRecording(_ recording: Recording) { self.recording = recording }
    func didFailWithError(_ error: Error) {}
}

private final class MockRecordingRepositoryForTests: RecordingRepositoryProtocol {
    var fetchByIdCalled = false
    func fetchAll() async throws -> [Recording] { [] }
    func delete(_ recording: Recording) async throws {}
    func save(_ recording: Recording) async throws {}
    func fetch(by id: UUID) async throws -> Recording? {
        fetchByIdCalled = true
        return nil
    }
    func update(_ recording: Recording) async throws {}
}
