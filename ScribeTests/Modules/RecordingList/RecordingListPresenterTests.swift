import XCTest
@testable import Scribe

final class RecordingListPresenterTests: XCTestCase {
    private var presenter: RecordingListPresenter!
    private var mockInteractor: MockInteractor!
    private var mockRouter: MockRouter!
    
    override func setUp() {
        super.setUp()
        mockInteractor = MockInteractor()
        mockRouter = MockRouter()
        presenter = RecordingListPresenter(
            view: nil,
            interactor: mockInteractor,
            router: mockRouter
        )
    }
    
    func testDidTriggerViewReadyCallsInteractor() {
        presenter.didTriggerViewReady()
        XCTAssertTrue(mockInteractor.obtainRecordingsCalled)
    }
    
    func testDidDeleteRecordingCallsInteractor() {
        presenter.didDeleteRecording(id: "test-id")
        XCTAssertTrue(mockInteractor.deleteCalled)
    }
}

private final class MockInteractor: RecordingListInteractorInput {
    var obtainRecordingsCalled = false
    var deleteCalled = false
    
    func obtainRecordings() {
        obtainRecordingsCalled = true
    }
    
    func deleteRecording(id: String) {
        deleteCalled = true
    }
}

private final class MockRouter: RecordingListRouterInput {
    func openRecordingDetail(with recording: Recording) {}
    func openDeviceSettings() {}
    func openAgentGenerating() {}
}
