import XCTest
import Combine
@testable import Scribe

final class UnifiedRecorderTests: XCTestCase {
    
    private var unifiedRecorder: UnifiedRecorder!
    private var mockInternalRecorder: EnhancedMockAudioRecorder!
    private var mockAudioStream: MockAudioStream!
    private var mockConnectionManager: EnhancedMockDeviceConnectionManager!
    private var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        mockInternalRecorder = EnhancedMockAudioRecorder()
        mockAudioStream = MockAudioStream()
        mockConnectionManager = EnhancedMockDeviceConnectionManager()
        cancellables = []
    }
    
    override func tearDown() {
        cancellables = nil
        unifiedRecorder = nil
        mockInternalRecorder = nil
        mockAudioStream = nil
        mockConnectionManager = nil
        super.tearDown()
    }
    
    private func createUnifiedRecorder() {
        unifiedRecorder = UnifiedRecorder(
            internalRecorder: mockInternalRecorder,
            bleStream: mockAudioStream,
            connectionManager: mockConnectionManager
        )
    }
    
    // MARK: - Initialization Tests
    
    func testInitialization() {
        createUnifiedRecorder()
        
        XCTAssertNotNil(unifiedRecorder)
        XCTAssertNotNil(unifiedRecorder.isRecordingPublisher)
        XCTAssertNotNil(unifiedRecorder.recordingSourcePublisher)
    }
    
    func testInitialRecordingStateIsFalse() {
        createUnifiedRecorder()
        
        var initialState: Bool?
        
        unifiedRecorder.isRecordingPublisher
            .first()
            .sink { state in
                initialState = state
            }
            .store(in: &cancellables)
        
        XCTAssertEqual(initialState, false)
    }
    
    func testInitialRecordingSourceIsNil() {
        createUnifiedRecorder()
        
        var initialSource: RecordingSource?
        
        unifiedRecorder.recordingSourcePublisher
            .first()
            .sink { source in
                initialSource = source
            }
            .store(in: &cancellables)
        
        XCTAssertNil(initialSource)
    }
    
    // MARK: - BLE Disconnected Routing Tests
    
    func testStartRecordingWithBLEDisconnectedUsesInternalMic() {
        mockConnectionManager.mockSetConnectionState(.disconnected)
        createUnifiedRecorder()
        
        var receivedSource: RecordingSource?
        
        unifiedRecorder.recordingSourcePublisher
            .sink { source in
                if let source = source {
                    receivedSource = source
                }
            }
            .store(in: &cancellables)
        
        unifiedRecorder.startRecording()
        
        XCTAssertTrue(mockInternalRecorder.startRecordingCalled)
        XCTAssertEqual(receivedSource, .rawInternal)
    }
    
    func testStartRecordingWithBLEDisconnectedDoesNotStartBLEStream() {
        mockConnectionManager.mockSetConnectionState(.disconnected)
        createUnifiedRecorder()
        
        unifiedRecorder.startRecording()
        
        XCTAssertFalse(mockAudioStream.startStreamingCalled)
    }
    
    // MARK: - BLE Connected Routing Tests
    
    func testStartRecordingWithBLEConnectedUsesBLEStream() {
        mockConnectionManager.mockSetConnectionState(.connected)
        createUnifiedRecorder()
        
        var receivedSource: RecordingSource?
        
        unifiedRecorder.recordingSourcePublisher
            .sink { source in
                if let source = source {
                    receivedSource = source
                }
            }
            .store(in: &cancellables)
        
        unifiedRecorder.startRecording()
        
        XCTAssertTrue(mockAudioStream.startStreamingCalled)
    }
    
    func testStartRecordingWithBLEConnectedDoesNotStartInternalRecorder() {
        mockConnectionManager.mockSetConnectionState(.connected)
        createUnifiedRecorder()
        
        unifiedRecorder.startRecording()
        
        XCTAssertFalse(mockInternalRecorder.startRecordingCalled)
    }
    
    func testStartRecordingWithBLEBoundUsesBLEStream() {
        mockConnectionManager.mockSetConnectionState(.bound)
        createUnifiedRecorder()
        
        unifiedRecorder.startRecording()
        
        XCTAssertTrue(mockAudioStream.startStreamingCalled)
    }
    
    // MARK: - Is Recording State Tests
    
    func testStartRecordingEmitsTrueToIsRecordingPublisher() {
        mockConnectionManager.mockSetConnectionState(.disconnected)
        createUnifiedRecorder()
        
        var receivedStates: [Bool] = []
        
        unifiedRecorder.isRecordingPublisher
            .sink { state in
                receivedStates.append(state)
            }
            .store(in: &cancellables)
        
        unifiedRecorder.startRecording()
        
        XCTAssertTrue(receivedStates.contains(true))
    }
    
    func testStopRecordingEmitsFalseToIsRecordingPublisher() async {
        mockConnectionManager.mockSetConnectionState(.disconnected)
        createUnifiedRecorder()
        
        var receivedStates: [Bool] = []
        
        unifiedRecorder.isRecordingPublisher
            .sink { state in
                receivedStates.append(state)
            }
            .store(in: &cancellables)
        
        unifiedRecorder.startRecording()
        _ = await unifiedRecorder.stopRecording()
        
        XCTAssertTrue(receivedStates.contains(false))
    }
    
    // MARK: - Stop Recording Tests
    
    func testStopRecordingReturnsRecording() async {
        mockConnectionManager.mockSetConnectionState(.disconnected)
        createUnifiedRecorder()
        
        unifiedRecorder.startRecording()
        
        let recording = await unifiedRecorder.stopRecording()
        
        XCTAssertNotNil(recording)
    }
    
    func testStopRecordingReturnsNilWhenNotRecording() async {
        createUnifiedRecorder()
        
        let recording = await unifiedRecorder.stopRecording()
        
        XCTAssertNil(recording)
    }
    
    func testStopRecordingStopsInternalRecorder() async {
        mockConnectionManager.mockSetConnectionState(.disconnected)
        createUnifiedRecorder()
        
        unifiedRecorder.startRecording()
        _ = await unifiedRecorder.stopRecording()
        
        XCTAssertTrue(mockInternalRecorder.stopRecordingCalled)
    }
    
    func testStopRecordingStopsBLEStream() async {
        mockConnectionManager.mockSetConnectionState(.connected)
        createUnifiedRecorder()
        
        unifiedRecorder.startRecording()
        _ = await unifiedRecorder.stopRecording()
        
        XCTAssertTrue(mockAudioStream.stopStreamingCalled)
    }
    
    func testStopRecordingClearsSource() async {
        mockConnectionManager.mockSetConnectionState(.disconnected)
        createUnifiedRecorder()
        
        var sourceAfterStop: RecordingSource?
        
        unifiedRecorder.recordingSourcePublisher
            .dropFirst()
            .sink { source in
                sourceAfterStop = source
            }
            .store(in: &cancellables)
        
        unifiedRecorder.startRecording()
        _ = await unifiedRecorder.stopRecording()
        
        XCTAssertNil(sourceAfterStop)
    }
    
    // MARK: - BLE Disconnect Mid-Recording Tests
    
    func testRecordingStopsCleanlyOnDisconnect() async {
        mockConnectionManager.mockSetConnectionState(.connected)
        createUnifiedRecorder()
        
        unifiedRecorder.startRecording()
        
        mockConnectionManager.mockSetConnectionState(.disconnected)
        mockConnectionManager.mockSimulateDisconnect()
        
        let recording = await unifiedRecorder.stopRecording()
        
        XCTAssertNotNil(recording)
    }
    
    func testStopRecordingSavesPartialRecordingOnBLEDisconnect() async {
        mockConnectionManager.mockSetConnectionState(.connected)
        createUnifiedRecorder()
        
        unifiedRecorder.startRecording()
        
        mockAudioStream.mockSendAudioData(Data([0x00, 0x01, 0x02, 0x03]))
        
        mockConnectionManager.mockSetConnectionState(.disconnected)
        
        let recording = await unifiedRecorder.stopRecording()
        
        XCTAssertNotNil(recording)
        if let rec = recording {
            XCTAssertFalse(rec.fileName.isEmpty)
            XCTAssertFalse(rec.filePath.isEmpty)
        }
    }
    
    func testInternalRecorderStopsCleanly() async {
        mockConnectionManager.mockSetConnectionState(.disconnected)
        createUnifiedRecorder()
        
        unifiedRecorder.startRecording()
        mockInternalRecorder.mockSendAudioData(Data([0x00, 0x01, 0x02, 0x03]))
        
        let recording = await unifiedRecorder.stopRecording()
        
        XCTAssertNotNil(recording)
    }
    
    // MARK: - Multiple Start Calls Tests
    
    func testMultipleStartCallsHandledGracefully() {
        mockConnectionManager.mockSetConnectionState(.disconnected)
        createUnifiedRecorder()
        
        var trueCount = 0
        
        unifiedRecorder.isRecordingPublisher
            .sink { state in
                if state {
                    trueCount += 1
                }
            }
            .store(in: &cancellables)
        
        unifiedRecorder.startRecording()
        unifiedRecorder.startRecording()
        unifiedRecorder.startRecording()
        
        XCTAssertEqual(trueCount, 1)
    }
    
    // MARK: - Recording Properties Tests
    
    func testRecordingHasCorrectSourceForInternalMic() async {
        mockConnectionManager.mockSetConnectionState(.disconnected)
        createUnifiedRecorder()
        
        unifiedRecorder.startRecording()
        let recording = await unifiedRecorder.stopRecording()
        
        XCTAssertEqual(recording?.source, .rawInternal)
    }
    
    func testRecordingHasDuration() async {
        mockConnectionManager.mockSetConnectionState(.disconnected)
        createUnifiedRecorder()
        
        unifiedRecorder.startRecording()
        
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        let recording = await unifiedRecorder.stopRecording()
        
        XCTAssertGreaterThan(recording?.duration ?? 0, 0)
    }
}

// MARK: - Mock Audio Stream

class MockAudioStream: AudioStreamProtocol {
    var audioDataPublisher: AnyPublisher<Data, Never> {
        audioDataSubject.eraseToAnyPublisher()
    }
    
    private let audioDataSubject = PassthroughSubject<Data, Never>()
    
    private(set) var startStreamingCalled = false
    private(set) var stopStreamingCalled = false
    
    func startStreaming() {
        startStreamingCalled = true
    }
    
    func stopStreaming() {
        stopStreamingCalled = true
    }
    
    func mockSendAudioData(_ data: Data) {
        audioDataSubject.send(data)
    }
    
    func reset() {
        startStreamingCalled = false
        stopStreamingCalled = false
    }
}

// MARK: - Enhanced Mock Audio Recorder

final class EnhancedMockAudioRecorder: AudioRecorderProtocol {
    var isRecordingPublisher: AnyPublisher<Bool, Never> {
        isRecordingSubject.eraseToAnyPublisher()
    }
    var audioDataPublisher: AnyPublisher<Data, Never> {
        audioDataSubject.eraseToAnyPublisher()
    }
    
    private let isRecordingSubject = CurrentValueSubject<Bool, Never>(false)
    private let audioDataSubject = PassthroughSubject<Data, Never>()
    
    private(set) var startRecordingCalled = false
    private(set) var stopRecordingCalled = false
    
    func startRecording(source: RecordingSource) {
        startRecordingCalled = true
        isRecordingSubject.send(true)
    }
    
    func stopRecording() async -> Recording? {
        stopRecordingCalled = true
        isRecordingSubject.send(false)
        return nil
    }
    
    func mockSendAudioData(_ data: Data) {
        audioDataSubject.send(data)
    }
    
    func reset() {
        startRecordingCalled = false
        stopRecordingCalled = false
    }
}

// MARK: - Enhanced Mock Connection Manager

final class EnhancedMockDeviceConnectionManager: DeviceConnectionManagerProtocol {
    var connectionStatePublisher: AnyPublisher<ConnectionState, Never> {
        connectionStateSubject.eraseToAnyPublisher()
    }
    var audioDataPublisher: AnyPublisher<Data, Never> {
        audioDataSubject.eraseToAnyPublisher()
    }
    
    private let connectionStateSubject: CurrentValueSubject<ConnectionState, Never>
    private let audioDataSubject = PassthroughSubject<Data, Never>()
    
    init(initialState: ConnectionState = .disconnected) {
        connectionStateSubject = CurrentValueSubject<ConnectionState, Never>(initialState)
    }
    
    func connect(to device: BluetoothDevice) {
        connectionStateSubject.send(.connecting)
        connectionStateSubject.send(.connected)
    }
    
    func disconnect() {
        connectionStateSubject.send(.disconnected)
    }
    
    func sendCommand(_ command: Data) {}
    
    func mockSetConnectionState(_ state: ConnectionState) {
        connectionStateSubject.send(state)
    }
    
    func mockSimulateDisconnect() {
        connectionStateSubject.send(.disconnected)
    }
    
    func mockSendAudioData(_ data: Data) {
        audioDataSubject.send(data)
    }
}
