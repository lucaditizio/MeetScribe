import XCTest
@testable import Scribe

final class SummaryTests: XCTestCase {
    func testTopicSectionInitialization() {
        let topic = TopicSection(
            title: "Key Discussion Points",
            content: "We discussed the project timeline and deliverables.",
            order: 1
        )
        
        XCTAssertEqual(topic.title, "Key Discussion Points")
        XCTAssertEqual(topic.order, 1)
        XCTAssertNotNil(topic.id)
    }
    
    func testMeetingSummaryInitialization() {
        let recordingId = UUID()
        let summary = MeetingSummary(
            recordingId: recordingId,
            overview: "Project kickoff meeting",
            keyPoints: ["Timeline set", "Budget approved"],
            actionItems: ["Send follow-up email"]
        )
        
        XCTAssertEqual(summary.recordingId, recordingId)
        XCTAssertEqual(summary.overview, "Project kickoff meeting")
        XCTAssertEqual(summary.keyPoints.count, 2)
        XCTAssertEqual(summary.actionItems.count, 1)
        XCTAssertNotNil(summary.id)
    }
}
