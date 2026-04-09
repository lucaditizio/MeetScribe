import XCTest
import Combine
@testable import Scribe

final class InternalMicRecorderTests: XCTestCase {
    private var recorder: InternalMicRecorder!
    private var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        recorder = InternalMicRecorder()
        cancellables = []
    }
    
    override func tearDown() {
        cancellables = nil
        recorder = nil
        super.tearDown()
    }
    
    func testStartRecordingEmitsTrueToIsRecordingPublisher() {
        var receivedStates: [Bool] = []
        
        recorder.isRecordingPublisher
            .sink { state in
                receivedStates.append(state)
            }
            .store(in: &cancellables)
        
        XCTAssertEqual(receivedStates.first, false, "Initial state should be not recording")
        
        recorder.startRecording(source: .rawInternal)
        
        XCTAssertTrue(receivedStates.contains(true), "isRecordingPublisher should emit true after startRecording")
    }
    
    func testStopRecordingEmitsFalseToIsRecordingPublisher() async {
        var receivedStates: [Bool] = []
        
        recorder.isRecordingPublisher
            .sink { state in
                receivedStates.append(state)
            }
            .store(in: &cancellables)
        
        recorder.startRecording(source: .rawInternal)
        
        let recording = await recorder.stopRecording()
        
        XCTAssertTrue(receivedStates.contains(false), "isRecordingPublisher should emit false after stopRecording")
    }
    
    func testStopRecordingReturnsNilWhenNotRecording() async {
        let recording = await recorder.stopRecording()
        
        XCTAssertNil(recording, "stopRecording should return nil when not in recording state")
    }
    
    func testMultipleStartCallsHandledGracefully() {
        var receivedStates: [Bool] = []
        
        recorder.isRecordingPublisher
            .sink { state in
                receivedStates.append(state)
            }
            .store(in: &cancellables)
        
        recorder.startRecording(source: .rawInternal)
        recorder.startRecording(source: .rawInternal)
        recorder.startRecording(source: .rawInternal)
        
        let trueCount = receivedStates.filter { $0 == true }.count
        XCTAssertEqual(trueCount, 1)
    }
    
    func testStopRecordingReturnsRecordingObject() async {
        recorder.startRecording(source: .rawInternal)
        
        let recording = await recorder.stopRecording()
        
        XCTAssertNotNil(recording, "stopRecording should return a Recording object when recording was active")
        
        if let recording = recording {
            XCTAssertEqual(recording.source, .rawInternal, "Recording source should be rawInternal")
            XCTAssertGreaterThan(recording.duration, 0, "Duration should be greater than 0")
            XCTAssertFalse(recording.fileName.isEmpty, "FileName should not be empty")
            XCTAssertFalse(recording.filePath.isEmpty, "FilePath should not be empty")
        }
    }
    
    func testRecordingObjectHasCorrectProperties() async {
        recorder.startRecording(source: .rawInternal)
        
        let recording = await recorder.stopRecording()
        
        XCTAssertNotNil(recording)
        
        if let recording = recording {
            XCTAssertNotNil(recording.id, "Recording should have a UUID id")
            XCTAssertNotNil(recording.title, "Recording should have a title")
            XCTAssertNotNil(recording.date, "Recording should have a date")
            XCTAssertNotNil(recording.createdAt, "Recording should have createdAt")
            XCTAssertNotNil(recording.updatedAt, "Recording should have updatedAt")
        }
    }
    
    func testIsRecordingPublisherInitialValueIsFalse() {
        var initialState: Bool?
        
        recorder.isRecordingPublisher
            .first()
            .sink { state in
                initialState = state
            }
            .store(in: &cancellables)
        
        XCTAssertEqual(initialState, false, "isRecordingPublisher should initially emit false")
    }
    
    func testAudioDataPublisherExists() {
        XCTAssertNotNil(recorder.audioDataPublisher, "audioDataPublisher should exist")
    }
}
