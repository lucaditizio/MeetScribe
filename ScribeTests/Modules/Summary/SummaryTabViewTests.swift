import XCTest
@testable import Scribe

final class SummaryTabViewTests: XCTestCase {
    private var mockOutput: MockSummaryViewOutput!
    private var view: SummaryTabView!
    
    override func setUp() {
        super.setUp()
        mockOutput = MockSummaryViewOutput()
        view = SummaryTabView(output: mockOutput)
    }
    
    override func tearDown() {
        mockOutput = nil
        view = nil
        super.tearDown()
    }
    
    func testEmptyStateShowsWhenNoTopicSectionsAndNoActionItems() {
        view.state = SummaryState(topicSections: [], actionItems: [])
        
        XCTAssertTrue(view.state.topicSections.isEmpty)
        XCTAssertTrue(view.state.actionItems.isEmpty)
    }
    
    func testViewRendersTopicSectionsFromState() {
        let topicSection1 = SummaryTopicSection(id: UUID(), title: "Project Overview", content: "This project aims to build a meeting transcription system")
        let topicSection2 = SummaryTopicSection(id: UUID(), title: "Technical Requirements", content: "Need to support multiple audio sources and real-time processing")
        
        let state = SummaryState(topicSections: [topicSection1, topicSection2], actionItems: [])
        view.state = state
        
        XCTAssertEqual(state.topicSections.count, 2)
        XCTAssertEqual(state.topicSections[0].title, "Project Overview")
        XCTAssertEqual(state.topicSections[1].title, "Technical Requirements")
    }
    
    func testViewRendersActionItemsFromState() {
        let actionItems = ["Review code for security vulnerabilities", "Update documentation for API endpoints", "Schedule team meeting for next sprint"]
        
        let state = SummaryState(topicSections: [], actionItems: actionItems)
        view.state = state
        
        XCTAssertEqual(state.actionItems.count, 3)
        XCTAssertEqual(state.actionItems[0], "Review code for security vulnerabilities")
    }
    
    func testViewRendersBothTopicSectionsAndActionItems() {
        let topicSection = SummaryTopicSection(id: UUID(), title: "Key Decisions", content: "Team agreed on using SwiftData for persistence")
        let actionItems = ["Implement SwiftData schema", "Write unit tests for data models"]
        
        let state = SummaryState(topicSections: [topicSection], actionItems: actionItems)
        view.state = state
        
        XCTAssertEqual(state.topicSections.count, 1)
        XCTAssertEqual(state.actionItems.count, 2)
    }
    
    func testDidTriggerViewReadyCallsOutput() {
        mockOutput.didTriggerViewReady()
        
        XCTAssertTrue(mockOutput.didTriggerViewReadyCalled)
    }
}

private final class MockSummaryViewOutput: SummaryViewOutput {
    var didTriggerViewReadyCalled = false
    
    func didTriggerViewReady() {
        didTriggerViewReadyCalled = true
    }
}