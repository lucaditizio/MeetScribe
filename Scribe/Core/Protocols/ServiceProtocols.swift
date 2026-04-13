import Foundation
import Combine

// Note: BluetoothDevice and ScannerConnectionDelegate are in Services/BLEService/BluetoothDevice.swift

// MARK: - BLE Service Protocols

/// Protocol for BLE device scanning
public protocol BluetoothDeviceScannerProtocol: AnyObject {
    var devicesPublisher: AnyPublisher<[BluetoothDevice], Never> { get }
    var isScanningPublisher: AnyPublisher<Bool, Never> { get }
    
    func startScan()
    func stopScan()
}

/// Protocol for BLE device connection management
public protocol DeviceConnectionManagerProtocol: AnyObject {
    var connectionStatePublisher: AnyPublisher<ConnectionState, Never> { get }
    var audioDataPublisher: AnyPublisher<Data, Never> { get }
    var isConnected: Bool { get }
    
    func connect(to device: BluetoothDevice)
    func disconnect()
    func sendCommand(_ command: Data)
}

/// Connection state for BLE devices with 9 states per plan specification
public enum ConnectionState: Equatable {
    case disconnected
    case connecting
    case connected
    case binding
    case initializing
    case initialized
    case bound
    case failed(String)
    case reconnecting(Int)
    
    public var isError: Bool {
        if case .failed = self { return true }
        return false
    }
    
    public var isConnected: Bool {
        switch self {
        case .connected, .binding, .initializing, .initialized, .bound:
            return true
        default:
            return false
        }
    }
}

// MARK: - Audio Service Protocols

/// Protocol for recording audio from internal mic or BLE
public protocol AudioRecorderProtocol: AnyObject {
    var isRecordingPublisher: AnyPublisher<Bool, Never> { get }
    var audioDataPublisher: AnyPublisher<Data, Never> { get }
    
    func startRecording(source: RecordingSource)
    func stopRecording() async -> Recording?
}

/// Protocol for audio playback
public protocol AudioPlayerProtocol: AnyObject {
    var playbackStatePublisher: AnyPublisher<PlaybackState, Never> { get }
    var currentTimePublisher: AnyPublisher<TimeInterval, Never> { get }
    
    func load(url: URL)
    func play()
    func pause()
    func seek(to time: TimeInterval)
    func stop()
    func setRate(_ rate: Float)
}

/// Playback state
public enum PlaybackState: Sendable {
    case idle
    case loading
    case playing
    case paused
    case error(Error)
}

/// Protocol for waveform generation
public protocol WaveformGeneratorProtocol: AnyObject {
    func generateWaveform(from url: URL, targetSampleCount: Int) async throws -> [AudioSample]
}

/// Protocol for waveform analysis
public protocol WaveformAnalyzerProtocol: AnyObject {
    func analyze(url: URL, barCount: Int) async throws -> [AudioSample]
}

// MARK: - ML Service Protocols

/// Protocol for Voice Activity Detection
public protocol VADServiceProtocol: AnyObject {
    func process(buffer: Data) -> Bool
    func hasSpeech(audioURL: URL) async throws -> Bool
}

/// Language detection result with confidence
public struct LanguageConfidence: Sendable {
    public let language: String
    public let confidence: Double
    public let isSwissGerman: Bool
    
    public init(language: String, confidence: Double, isSwissGerman: Bool) {
        self.language = language
        self.confidence = confidence
        self.isSwissGerman = isSwissGerman
    }
}

/// Protocol for language detection
public protocol LanguageDetectionProtocol: AnyObject {
    func detectLanguage(from audioData: Data) async throws -> LanguageConfidence
}

/// Protocol for Automatic Speech Recognition
public protocol ASRServiceProtocol: AnyObject {
    func transcribe(audioData: Data, language: String?) async throws -> String
}

/// Protocol for speaker diarization
public protocol DiarizationServiceProtocol: AnyObject {
    func diarize(audioData: Data, maxSpeakers: Int) async throws -> [SpeakerSegment]
}

/// Protocol for LLM summarization
public protocol LLMServiceProtocol: AnyObject {
    func summarize(text: String) async throws -> MeetingSummary
    func generateMindMap(from text: String) async throws -> [MindMapNode]
}

/// Protocol for managing ML pipeline
public protocol InferencePipelineProtocol: AnyObject {
    var progressPublisher: AnyPublisher<InferenceProgress, Never> { get }
    
    func process(recording: Recording) async throws -> (Transcript, MeetingSummary)
    func cancel()
}

// MARK: - Additional Service Protocols

/// Protocol for audio transcription services
public protocol TranscriptionServiceProtocol: AnyObject {
    func transcribe(audioData: Data, language: String?) async throws -> String
    func detectLanguage(audioData: Data) async throws -> String
}

/// Protocol for text summarization services
public protocol SummarizationServiceProtocol: AnyObject {
    func summarize(text: String) async throws -> MeetingSummary
}

/// Protocol for audio streaming from BLE device
public protocol AudioStreamProtocol: AnyObject {
    var audioDataPublisher: AnyPublisher<Data, Never> { get }
    func startStreaming()
    func stopStreaming()
}

/// Progress update for inference
public struct InferenceProgress: Sendable {
    public let stage: String
    public let progress: Double
    
    public init(stage: String, progress: Double) {
        self.stage = stage
        self.progress = progress
    }
}

// MARK: - Repository Protocols

/// Protocol for recording data access
public protocol RecordingRepositoryProtocol: AnyObject {
    func save(_ recording: Recording) async throws
    func fetchAll() async throws -> [Recording]
    func fetch(by id: UUID) async throws -> Recording?
    func delete(_ recording: Recording) async throws
    func update(_ recording: Recording) async throws
}
