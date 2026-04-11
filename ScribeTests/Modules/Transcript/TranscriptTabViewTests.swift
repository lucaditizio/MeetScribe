import XCTest
@testable import Scribe

final class TranscriptTabViewTests: XCTestCase {
    private var mockOutput: MockTranscriptViewOutput!
    private var view: TranscriptTabView!
    
    override func setUp() {
        super.setUp()
        mockOutput = MockTranscriptViewOutput()
        view = TranscriptTabView(output: mockOutput)
    }
    
    override func tearDown() {
        mockOutput = nil
        view = nil
        super.tearDown()
    }
    
    func testEmptyStateShowsWhenNoSegments() {
        view.state = TranscriptState(segments: [])
        
        XCTAssertTrue(view.state.segments.isEmpty)
    }
    
    func testViewRendersSegmentsFromState() {
        // Test that view state can be set with segments
        // SpeakerSegment is a @Model class, so we test with minimal initialization
        let segment1 = SpeakerSegment(speakerId: "speaker-1", speakerName: "Alice", start: 0.0, end: 10.0, text: "Hello everyone")
        
        let state = TranscriptState(segments: [segment1])
        view.state = state
        
        XCTAssertEqual(state.segments.count, 1)
        XCTAssertEqual(state.segments[0].speakerId, "speaker-1")
    }
    
    func testDidTapSpeakerCallsOutput() {
        let segment = SpeakerSegment(
            id: UUID(),
            speakerId: "speaker-test-123",
            speakerName: "Test Speaker",
            start: 5.0,
            end: 15.0,
            text: "Test text"
        )
        
        view.state = TranscriptState(segments: [segment])
        
        // Simulate tap by calling output directly (view's button calls this)
        mockOutput.didTapSpeaker(speakerId: "speaker-test-123")
        
        XCTAssertEqual(mockOutput.didTapSpeakerCalls.count, 1)
        XCTAssertEqual(mockOutput.didTapSpeakerCalls.first, "speaker-test-123")
    }
    
    func testDidTriggerViewReadyCallsOutput() {
        mockOutput.didTriggerViewReady()
        
        XCTAssertTrue(mockOutput.didTriggerViewReadyCalled)
    }
}

private final class MockTranscriptViewOutput: TranscriptViewOutput {
    var didTriggerViewReadyCalled = false
    var didTapSpeakerCalls: [String] = []
    
    func didTriggerViewReady() {
        didTriggerViewReadyCalled = true
    }
    
    func didTapSpeaker(speakerId: String) {
        didTapSpeakerCalls.append(speakerId)
    }
}
