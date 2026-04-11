import XCTest
@testable import Scribe

final class TranscriptPresenterTests: XCTestCase {
    private var presenter: TranscriptPresenter!
    private var mockInteractor: MockInteractor!
    
    override func setUp() {
        super.setUp()
        mockInteractor = MockInteractor()
        presenter = TranscriptPresenter(view: nil, interactor: mockInteractor)
    }
    
    func testDidTriggerViewReadyCallsInteractor() {
        presenter.didTriggerViewReady()
        XCTAssertTrue(mockInteractor.obtainSegmentsCalled)
    }
    
    func testDidTapSpeakerSetsSelectedSpeaker() {
        presenter.didTapSpeaker(speakerId: "speaker-1")
        XCTAssertEqual(presenter.state.selectedSpeakerForRename, "speaker-1")
    }
}

private final class MockInteractor: TranscriptInteractorInput {
    var obtainSegmentsCalled = false
    var renameCalled = false
    
    func obtainTranscriptSegments() {
        obtainSegmentsCalled = true
    }
    
    func renameSpeaker(from oldName: String, to newName: String) {
        renameCalled = true
    }
}
