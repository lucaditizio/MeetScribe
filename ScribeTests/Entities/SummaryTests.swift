import XCTest
@testable import Scribe

final class SummaryTests: XCTestCase {
    func testTopicSectionInitialization() {
        let topic = TopicSection(
            topic: "Key Discussion Points",
            bullets: ["We discussed the project timeline", "Deliverables confirmed"],
            order: 1
        )
        
        XCTAssertEqual(topic.topic, "Key Discussion Points")
        XCTAssertEqual(topic.bullets.count, 2)
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
