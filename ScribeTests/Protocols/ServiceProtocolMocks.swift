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
    
    private let connectionStateSubject = CurrentValueSubject<ConnectionState, Never>(.disconnected)
    private let audioDataSubject = PassthroughSubject<Data, Never>()
    
    func connect(to device: BluetoothDevice) {
        connectionStateSubject.send(.connecting)
        connectionStateSubject.send(.connected)
    }
    
    func disconnect() {
        connectionStateSubject.send(.disconnected)
    }
    
    func sendCommand(_ command: Data) {}
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
    
    func startRecording(source: RecordingSource) {
        isRecordingSubject.send(true)
    }
    
    func stopRecording() async -> Recording? {
        isRecordingSubject.send(false)
        return nil
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
}
