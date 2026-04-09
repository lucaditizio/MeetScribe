import Foundation

/// Registry holding all service protocol references as stubs
/// Placeholder implementations that compile but crash with fatalError when called
public final class ServiceRegistry {
    
    // MARK: - Shared Instance
    public static let shared = ServiceRegistry()
    
    // MARK: - BLE Services
    public lazy var bluetoothDeviceScanner: BluetoothDeviceScannerProtocol = {
        fatalError("BluetoothDeviceScanner not implemented")
    }()
    
    public lazy var deviceConnectionManager: DeviceConnectionManagerProtocol = {
        fatalError("DeviceConnectionManager not implemented")
    }()
    
    // MARK: - Audio Services
    public lazy var audioRecorder: AudioRecorderProtocol = {
        fatalError("AudioRecorder not implemented")
    }()
    
    public lazy var audioPlayer: AudioPlayerProtocol = {
        fatalError("AudioPlayer not implemented")
    }()
    
    public lazy var waveformGenerator: WaveformGeneratorProtocol = {
        fatalError("WaveformGenerator not implemented")
    }()
    
    // MARK: - ML Services
    public lazy var vadService: VADServiceProtocol = {
        fatalError("VADService not implemented")
    }()
    
    public lazy var languageDetection: LanguageDetectionProtocol = {
        fatalError("LanguageDetection not implemented")
    }()
    
    public lazy var asrService: ASRServiceProtocol = {
        fatalError("ASRService not implemented")
    }()
    
    public lazy var diarizationService: DiarizationServiceProtocol = {
        fatalError("DiarizationService not implemented")
    }()
    
    public lazy var llmService: LLMServiceProtocol = {
        fatalError("LLMService not implemented")
    }()
    
    public lazy var inferencePipeline: InferencePipelineProtocol = {
        fatalError("InferencePipeline not implemented")
    }()
    
    // MARK: - Repository Services
    public lazy var recordingRepository: RecordingRepositoryProtocol = {
        fatalError("RecordingRepository not implemented")
    }()
    
    // MARK: - Initialization
    private init() {}
}
