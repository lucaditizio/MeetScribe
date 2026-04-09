import XCTest
@testable import Scribe

/// Tests to verify VIPER protocol conformance and structure
final class VIPERProtocolTests: XCTestCase {
    
    // MARK: - View Model Tests
    
    func testRecordingViewModelInitialization() {
        let viewModel = RecordingViewModel(
            id: UUID(),
            title: "Test Recording",
            date: "Apr 9, 2024",
            duration: "5:30",
            source: .rawInternal
        )
        
        XCTAssertEqual(viewModel.title, "Test Recording")
        XCTAssertEqual(viewModel.duration, "5:30")
        XCTAssertEqual(viewModel.source, .rawInternal)
    }
    
    func testRecordingDetailViewModelInitialization() {
        let viewModel = RecordingDetailViewModel(
            id: UUID(),
            title: "Test",
            date: "Apr 9, 2024",
            duration: "5:30",
            filePath: "/path/to/file.caf"
        )
        
        XCTAssertEqual(viewModel.filePath, "/path/to/file.caf")
    }
    
    func testSummaryViewModelInitialization() {
        let viewModel = SummaryViewModel(
            overview: "Meeting overview",
            keyPoints: ["Point 1", "Point 2"],
            actionItems: ["Action 1"]
        )
        
        XCTAssertEqual(viewModel.overview, "Meeting overview")
        XCTAssertEqual(viewModel.keyPoints.count, 2)
        XCTAssertEqual(viewModel.actionItems.count, 1)
    }
    
    func testMindMapNodeViewModelInitialization() {
        let childNode = MindMapNodeViewModel(
            id: UUID(),
            text: "Child",
            level: 1
        )
        
        let parentNode = MindMapNodeViewModel(
            id: UUID(),
            text: "Parent",
            level: 0,
            children: [childNode]
        )
        
        XCTAssertEqual(parentNode.text, "Parent")
        XCTAssertEqual(parentNode.level, 0)
        XCTAssertEqual(parentNode.children.count, 1)
        XCTAssertEqual(childNode.level, 1)
    }
    
    // MARK: - Protocol Conformance Tests
    
    func testViewModelsAreSendable() {
        // These should compile if properly marked as Sendable
        let recordingVM: Sendable = RecordingViewModel(
            id: UUID(),
            title: "Test",
            date: "Today",
            duration: "1:00",
            source: .rawBle
        )
        
        let detailVM: Sendable = RecordingDetailViewModel(
            id: UUID(),
            title: "Test",
            date: "Today",
            duration: "1:00",
            filePath: "/test.caf"
        )
        
        let summaryVM: Sendable = SummaryViewModel(
            overview: "Test",
            keyPoints: [],
            actionItems: []
        )
        
        let mindMapVM: Sendable = MindMapNodeViewModel(
            id: UUID(),
            text: "Root",
            level: 0
        )
        
        XCTAssertNotNil(recordingVM)
        XCTAssertNotNil(detailVM)
        XCTAssertNotNil(summaryVM)
        XCTAssertNotNil(mindMapVM)
    }
    
    func testViewModelsAreIdentifiable() {
        let id = UUID()
        let vm = RecordingViewModel(
            id: id,
            title: "Test",
            date: "Today",
            duration: "1:00",
            source: .rawInternal
        )
        
        XCTAssertEqual(vm.id, id)
    }
}
