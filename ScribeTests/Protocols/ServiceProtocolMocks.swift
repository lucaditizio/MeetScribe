import Foundation
import Combine
@testable import Scribe

// MARK: - BLE Mocks

class MockBluetoothDeviceScanner: BluetoothDeviceScannerProtocol {
    var devicesPublisher: AnyPublisher<[BluetoothDevice], Never> {
        devicesSubject.eraseToAnyPublisher()
    }
    var isScanningPublisher: AnyPublisher<Bool, Never> {
        isScanningSubject.eraseToAnyPublisher()
    }
    
    private let devicesSubject = CurrentValueSubject<[BluetoothDevice], Never>([])
    private let isScanningSubject = CurrentValueSubject<Bool, Never>(false)
    
    func startScan() {
        isScanningSubject.send(true)
    }
    
    func stopScan() {
        isScanningSubject.send(false)
    }
    
    func mockDeviceDiscovery(_ devices: [BluetoothDevice]) {
        devicesSubject.send(devices)
    }
}

class MockDeviceConnectionManager: DeviceConnectionManagerProtocol {
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

    func mockSendAudioData(_ data: Data) {
        audioDataSubject.send(data)
    }
}

// MARK: - Audio Mocks

class MockAudioRecorder: AudioRecorderProtocol {
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
    private(set) var lastRecordingSource: RecordingSource?
    var shouldReturnRecording = true
    var mockRecordingDuration: TimeInterval = 1.0
    
    func startRecording(source: RecordingSource) {
        guard !isRecordingSubject.value else { return }
        startRecordingCalled = true
        lastRecordingSource = source
        isRecordingSubject.send(true)
    }
    
    func stopRecording() async -> Recording? {
        stopRecordingCalled = true
        isRecordingSubject.send(false)
        
        guard shouldReturnRecording else { return nil }
        
        return Recording(
            title: "Test Recording",
            date: Date(),
            duration: mockRecordingDuration,
            fileName: "test-recording.caf",
            filePath: "/test/path/test-recording.caf",
            source: lastRecordingSource ?? .rawInternal
        )
    }
    
    func mockSendAudioData(_ data: Data) {
        audioDataSubject.send(data)
    }
    
    func reset() {
        startRecordingCalled = false
        stopRecordingCalled = false
        lastRecordingSource = nil
        shouldReturnRecording = true
        mockRecordingDuration = 1.0
        isRecordingSubject.send(false)
    }
}

class MockAudioPlayer: AudioPlayerProtocol {
    var playbackStatePublisher: AnyPublisher<PlaybackState, Never> {
        playbackStateSubject.eraseToAnyPublisher()
    }
    var currentTimePublisher: AnyPublisher<TimeInterval, Never> {
        currentTimeSubject.eraseToAnyPublisher()
    }
    
    private let playbackStateSubject = CurrentValueSubject<PlaybackState, Never>(.idle)
    private let currentTimeSubject = CurrentValueSubject<TimeInterval, Never>(0)
    
    func load(url: URL) {
        playbackStateSubject.send(.loading)
    }
    
    func play() {
        playbackStateSubject.send(.playing)
    }
    
    func pause() {
        playbackStateSubject.send(.paused)
    }
    
    func seek(to time: TimeInterval) {
        currentTimeSubject.send(time)
    }
    
    func stop() {
        playbackStateSubject.send(.idle)
        currentTimeSubject.send(0)
    }
}

// MARK: - Repository Mock

class MockRecordingRepository: RecordingRepositoryProtocol {
    private var recordings: [Recording] = []
    
    func save(_ recording: Recording) async throws {
        recordings.append(recording)
    }
    
    func fetchAll() async throws -> [Recording] {
        return recordings
    }
    
    func fetch(by id: UUID) async throws -> Recording? {
        return recordings.first { $0.id == id }
    }
    
    func delete(_ recording: Recording) async throws {
        recordings.removeAll { $0.id == recording.id }
    }
    
    func update(_ recording: Recording) async throws {
        if let index = recordings.firstIndex(where: { $0.id == recording.id }) {
            recordings[index] = recording
        }
    }
}
