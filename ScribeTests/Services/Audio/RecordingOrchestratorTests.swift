import XCTest
import Combine
@testable import Scribe

final class RecordingOrchestratorTests: XCTestCase {
    private var orchestrator: RecordingOrchestrator!
    private var mockRecorder: MockUnifiedRecorder!
    private var mockConnectionManager: MockDeviceConnectionManager!
    private var cancellables: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()
        mockRecorder = MockUnifiedRecorder()
        mockConnectionManager = MockDeviceConnectionManager()
        orchestrator = RecordingOrchestrator(
            unifiedRecorder: mockRecorder,
            connectionManager: mockConnectionManager,
            fallbackOnDisconnect: true
        )
        cancellables = []
    }

    override func tearDown() {
        cancellables = nil
        orchestrator = nil
        mockRecorder = nil
        mockConnectionManager = nil
        super.tearDown()
    }

    func testInitialization() {
        XCTAssertNotNil(orchestrator)
        XCTAssertNotNil(orchestrator.isRecordingPublisher)
        XCTAssertNotNil(orchestrator.recordingSourcePublisher)
        XCTAssertNotNil(orchestrator.recordingErrorPublisher)
        XCTAssertNotNil(orchestrator.didSwitchSourcePublisher)
    }

    func testInitialIsRecordingStateIsFalse() {
        var initialState: Bool?

        orchestrator.isRecordingPublisher
            .first()
            .sink { state in
                initialState = state
            }
            .store(in: &cancellables)

        XCTAssertEqual(initialState, false)
    }

    func testInitialRecordingSourceIsNil() {
        var initialSource: RecordingSource?

        orchestrator.recordingSourcePublisher
            .first()
            .sink { source in
                initialSource = source
            }
            .store(in: &cancellables)

        XCTAssertNil(initialSource)
    }

    func testStartRecordingCallsUnifiedRecorder() {
        orchestrator.startRecording()

        XCTAssertTrue(mockRecorder.startRecordingCalled)
    }

    func testStartRecordingEmitsTrueToIsRecordingPublisher() {
        mockRecorder.setIsRecording(true)

        var receivedStates: [Bool] = []
        orchestrator.isRecordingPublisher
            .sink { state in
                receivedStates.append(state)
            }
            .store(in: &cancellables)

        orchestrator.startRecording()

        XCTAssertTrue(receivedStates.contains(true))
    }

    func testStartRecordingWhenAlreadyRecordingEmitsError() {
        mockRecorder.setIsRecording(true)
        orchestrator.startRecording()

        var receivedError: RecordingOrchestratorError?
        orchestrator.recordingErrorPublisher
            .sink { error in
                receivedError = error
            }
            .store(in: &cancellables)

        orchestrator.startRecording()

        XCTAssertEqual(receivedError, .recordingAlreadyInProgress)
    }

    func testStopRecordingCallsUnifiedRecorder() async {
        mockRecorder.setIsRecording(true)
        orchestrator.startRecording()

        _ = await orchestrator.stopRecording()

        XCTAssertTrue(mockRecorder.stopRecordingCalled)
    }

    func testStopRecordingReturnsNilWhenNotRecording() async {
        mockRecorder.setIsRecording(false)

        let recording = await orchestrator.stopRecording()

        XCTAssertNil(recording)
    }

    func testStopRecordingReturnsRecording() async {
        let expectedRecording = Recording(
            title: "Test",
            date: Date(),
            duration: 5.0,
            fileName: "test.caf",
            filePath: "/test.caf",
            source: .rawInternal
        )
        mockRecorder.mockRecordingToReturn = expectedRecording
        mockRecorder.setIsRecording(true)
        orchestrator.startRecording()

        let recording = await orchestrator.stopRecording()

        XCTAssertNotNil(recording)
    }

    func testStopRecordingEmitsFalseToIsRecordingPublisher() async {
        mockRecorder.setIsRecording(true)
        orchestrator.startRecording()

        var receivedStates: [Bool] = []
        orchestrator.isRecordingPublisher
            .sink { state in
                receivedStates.append(state)
            }
            .store(in: &cancellables)

        _ = await orchestrator.stopRecording()

        XCTAssertTrue(receivedStates.contains(false))
    }

    func testSwitchSourceWhenNotRecordingEmitsError() {
        mockRecorder.setIsRecording(false)

        var receivedError: RecordingOrchestratorError?
        orchestrator.recordingErrorPublisher
            .sink { error in
                receivedError = error
            }
            .store(in: &cancellables)

        orchestrator.switchSource(to: .rawInternal)

        XCTAssertEqual(receivedError, .noActiveRecording)
    }

    func testSwitchSourceToSameSourceDoesNothing() {
        mockRecorder.setIsRecording(true)
        mockRecorder.setRecordingSource(.rawInternal)
        orchestrator.startRecording()

        var switchEmitted = false
        orchestrator.didSwitchSourcePublisher
            .sink { _ in
                switchEmitted = true
            }
            .store(in: &cancellables)

        orchestrator.switchSource(to: .rawInternal)

        XCTAssertFalse(switchEmitted)
    }

    func testBLEDisconnectWithFallbackEnabledSwitchesToInternal() {
        mockRecorder.setIsRecording(true)
        mockRecorder.setRecordingSource(.rawBle)
        orchestrator.startRecording()

        var switchOccurred = false
        orchestrator.didSwitchSourcePublisher
            .sink { _ in
                switchOccurred = true
            }
            .store(in: &cancellables)

        mockConnectionManager.mockSetConnectionState(.disconnected)

        XCTAssertTrue(switchOccurred)
    }

    func testBLEDisconnectWithFallbackDisabledStopsRecording() async {
        orchestrator.setFallbackOnDisconnect(false)
        mockRecorder.setIsRecording(true)
        mockRecorder.setRecordingSource(.rawBle)
        orchestrator.startRecording()

        mockConnectionManager.mockSetConnectionState(.disconnected)

        try? await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertTrue(mockRecorder.stopRecordingCalled)
    }

    func testIsRecordingProperty() {
        mockRecorder.setIsRecording(true)
        orchestrator.startRecording()

        XCTAssertTrue(orchestrator.isRecording)
    }

    func testCurrentSourceProperty() {
        mockRecorder.setRecordingSource(.rawBle)

        XCTAssertEqual(orchestrator.currentSource, .rawBle)
    }

    func testIsSwitchingSourceProperty() {
        XCTAssertFalse(orchestrator.isSwitchingSource)
    }

    func testConnectedStateDoesNotTriggerAction() {
        mockRecorder.setIsRecording(true)
        orchestrator.startRecording()

        var errorReceived = false
        orchestrator.recordingErrorPublisher
            .sink { _ in
                errorReceived = true
            }
            .store(in: &cancellables)

        mockConnectionManager.mockSetConnectionState(.connected)

        XCTAssertFalse(errorReceived)
    }

    func testFailedConnectionTriggersDisconnectHandling() {
        mockRecorder.setIsRecording(true)
        mockRecorder.setRecordingSource(.rawBle)
        orchestrator.startRecording()

        var switchOccurred = false
        orchestrator.didSwitchSourcePublisher
            .sink { _ in
                switchOccurred = true
            }
            .store(in: &cancellables)

        mockConnectionManager.mockSetConnectionState(.failed("Test error"))

        XCTAssertTrue(switchOccurred)
    }
}

final class MockUnifiedRecorder: UnifiedRecorder {
    private let isRecordingSubject = CurrentValueSubject<Bool, Never>(false)
    private let recordingSourceSubject = CurrentValueSubject<RecordingSource?, Never>(nil)

    private(set) var startRecordingCalled = false
    private(set) var stopRecordingCalled = false

    var mockRecordingToReturn: Recording?

    override var isRecordingPublisher: AnyPublisher<Bool, Never> {
        isRecordingSubject.eraseToAnyPublisher()
    }

    override var recordingSourcePublisher: AnyPublisher<RecordingSource?, Never> {
        recordingSourceSubject.eraseToAnyPublisher()
    }

    init() {
        super.init(
            internalRecorder: MockAudioRecorder(),
            bleStream: MockAudioStream(),
            connectionManager: MockDeviceConnectionManager()
        )
    }

    func setIsRecording(_ value: Bool) {
        isRecordingSubject.send(value)
    }

    func setRecordingSource(_ source: RecordingSource?) {
        recordingSourceSubject.send(source)
    }

    override func startRecording() {
        startRecordingCalled = true
        isRecordingSubject.send(true)
    }

    override func stopRecording() async -> Recording? {
        stopRecordingCalled = true
        isRecordingSubject.send(false)
        recordingSourceSubject.send(nil)
        return mockRecordingToReturn
    }
}
