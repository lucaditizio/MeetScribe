import XCTest
@testable import Scribe

final class RecordingDetailPresenterTests: XCTestCase {
    private var presenter: RecordingDetailPresenter!
    private var mockInteractor: MockInteractor!
    
    override func setUp() {
        super.setUp()
        mockInteractor = MockInteractor()
        presenter = RecordingDetailPresenter(view: nil, interactor: mockInteractor, router: MockRouter())
    }
    
    func testDidSelectTabChangesState() {
        presenter.didSelectTab(.transcript)
        XCTAssertEqual(presenter.state.selectedTab, .transcript)
        
        presenter.didSelectTab(.mindMap)
        XCTAssertEqual(presenter.state.selectedTab, .mindMap)
    }
}

private final class MockInteractor: RecordingDetailInteractorInput {
    func obtainRecording(id: String) {}
    func updateRecording(_ recording: Recording) {}
}

private final class MockRouter: RecordingDetailRouterInput {
    func embedWaveformPlayback(with recording: Recording) {}
    func embedTranscript(with recording: Recording) {}
    func embedSummary(with recording: Recording) {}
    func embedMindMap(with recording: Recording) {}
}
