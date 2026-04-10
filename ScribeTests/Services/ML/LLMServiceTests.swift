import XCTest
@testable import Scribe

final class LLMServiceTests: XCTestCase {
    private var llmService: LLMService!
    private var mockSummarizationService: MockSummarizationServiceForLLMTests!
    
    override func setUp() {
        super.setUp()
        llmService = LLMService()
        mockSummarizationService = MockSummarizationServiceForLLMTests()
    }
    
    override func tearDown() {
        llmService = nil
        mockSummarizationService = nil
        super.tearDown()
    }
    
    func testSummarizeSinglePassForShortText() async throws {
        let shortText = String(repeating: "This is a short meeting transcript. ", count: 100)
        
        let summary = try await llmService.summarize(text: shortText)
        
        XCTAssertEqual(summary.overview.count, 0)
        XCTAssertTrue(summary.keyPoints.isEmpty)
        XCTAssertTrue(summary.actionItems.isEmpty)
    }
    
    func testSummarizeMapRefineForLongText() async throws {
        let longText = String(repeating: "This is a long meeting transcript that exceeds the single pass threshold. ", count: 1000)
        
        let summary = try await llmService.summarize(text: longText)
        
        XCTAssertEqual(summary.overview.count, 0)
        XCTAssertTrue(summary.keyPoints.isEmpty)
        XCTAssertTrue(summary.actionItems.isEmpty)
    }
    
    func testEmptyTextThrowsError() async {
        do {
            _ = try await llmService.summarize(text: "")
            XCTFail("Should throw error for empty text")
        } catch {
            // Accept any error
            XCTAssertNotNil(error)
        }
    }
    
    func testParsingSuccessfulResponse() async throws {
        let mockResponse = """
        {
            "overview": "Meeting discussed project timeline",
            "keyPoints": ["Timeline approved", "Budget allocated"],
            "actionItems": ["Review by Friday"]
        }
        """
        
        let summary = try llmService.parseSummaryResponse(mockResponse)
        
        XCTAssertEqual(summary.overview, "Meeting discussed project timeline")
        XCTAssertEqual(summary.keyPoints.count, 2)
        XCTAssertEqual(summary.actionItems.count, 1)
    }
    
    func testParsingInvalidResponseThrowsError() async {
        let invalidResponse = "Not valid JSON"
        
        do {
            _ = try llmService.parseSummaryResponse(invalidResponse)
            XCTFail("Should throw error for invalid JSON")
        } catch {
            // Accept any error
            XCTAssertNotNil(error)
        }
    }
}

fileprivate final class MockSummarizationServiceForLLMTests: SummarizationServiceProtocol {
    func summarize(text: String) async throws -> MeetingSummary {
        return MeetingSummary(
            recordingId: UUID(),
            overview: "",
            keyPoints: [],
            actionItems: []
        )
    }
}
