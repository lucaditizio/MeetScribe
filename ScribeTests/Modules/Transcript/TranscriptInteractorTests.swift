import XCTest
@testable import Scribe

final class TranscriptInteractorTests: XCTestCase {
    private var interactor: TranscriptInteractor!
    private var mockOutput: MockInteractorOutput!
    private var mockRepository: MockRecordingRepositoryForTranscriptTests!
    
    override func setUp() {
        super.setUp()
        mockOutput = MockInteractorOutput()
        mockRepository = MockRecordingRepositoryForTranscriptTests()
        interactor = TranscriptInteractor(
            output: mockOutput,
            recordingRepository: mockRepository
        )
    }
    
    func testObtainTranscriptSegmentsCallsFetch() async {
        let testUUID = UUID()
        interactor.configureWith(recordingId: testUUID.uuidString)
        interactor.obtainTranscriptSegments()
        try? await Task.sleep(nanoseconds: 100_000_000)
        XCTAssertTrue(mockRepository.fetchByIdCalled)
    }
}

private final class MockInteractorOutput: TranscriptInteractorOutput {
    var segments: [SpeakerSegment] = []
    func didObtainTranscriptSegments(_ segments: [SpeakerSegment]) {
        self.segments = segments
    }
    func didFailWithError(_ error: Error) {}
}

private final class MockRecordingRepositoryForTranscriptTests: RecordingRepositoryProtocol {
    var fetchByIdCalled = false
    
    func fetch(by id: UUID) async throws -> Recording? {
        fetchByIdCalled = true
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
    func fetchAll() async throws -> [Recording] { [] }
    func delete(_ recording: Recording) async throws {}
    func save(_ recording: Recording) async throws {}
    func update(_ recording: Recording) async throws {}
}
