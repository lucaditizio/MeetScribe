import XCTest
import Combine
@testable import Scribe

final class AgentGeneratingInteractorTests: XCTestCase {
    private var interactor: AgentGeneratingInteractor!
    private var mockOutput: MockOutput!
    
    override func setUp() {
        mockOutput = MockOutput()
        interactor = AgentGeneratingInteractor(output: mockOutput, moduleOutput: nil, inferencePipeline: MockPipeline())
    }
    
    func testStartProcessingCallsPipeline() async {
        interactor.startProcessing(recordingId: "test-id")
        try? await Task.sleep(nanoseconds: 200_000_000)
        XCTAssertTrue(mockOutput.progressCalled)
    }
    
    func testCancelProcessingWorks() {
        interactor.startProcessing(recordingId: "test-id")
        interactor.cancelProcessing()
    }
}

private final class MockOutput: AgentGeneratingInteractorOutput {
    var progressCalled = false
    var completeCalled = false
    func didUpdateProgress(stage: String, progress: Double) { progressCalled = true }
    func didCompleteProcessing() { completeCalled = true }
    func didFailWithError(_ error: Error) {}
}

private final class MockPipeline: InferencePipelineProtocol {
    var progressPublisher: AnyPublisher<InferenceProgress, Never> { Just(InferenceProgress(stage: "Initializing", progress: 0)).eraseToAnyPublisher() }
    
    func process(recording: Recording) async throws -> (Transcript, MeetingSummary) {
        let transcript = Transcript(id: UUID(), recordingId: UUID(), fullText: "", detectedLanguage: nil, createdAt: Date())
        let summary = MeetingSummary(id: UUID(), recordingId: UUID(), overview: "", keyPoints: [], actionItems: [], createdAt: Date())
        return (transcript, summary)
    }
    
    func cancel() {}
}
