import Foundation

// MARK: - Protocol Conformance Extensions
// These extensions live here because WaveformAnalyzer, LLMService, and
// WhisperCoreMLService are defined in Services/ (outside the App layer).
// Placing conformances here keeps all App-layer wiring confined to App/.

/// Bridges WaveformAnalyzer to WaveformGeneratorProtocol by delegating to analyze().
extension WaveformAnalyzer: WaveformGeneratorProtocol {
    public func generateWaveform(from url: URL, targetSampleCount: Int) async throws -> [AudioSample] {
        try await analyze(url: url, barCount: targetSampleCount)
    }
}

/// Adds LLMServiceProtocol conformance to LLMService.
/// generateMindMap stubs out — the LLM inference is a future task.
extension LLMService: LLMServiceProtocol {
    public func generateMindMap(from text: String) async throws -> [MindMapNode] {
        throw LLMServiceError.notImplemented
    }
}

/// Adds ASRServiceProtocol conformance to WhisperCoreMLService.
/// Both protocols share the identical transcribe(audioData:language:) signature.
extension WhisperCoreMLService: ASRServiceProtocol {}

// MARK: - Service Registry

/// Registry of all service singletons. Used as the single source of truth
/// for DI throughout the Assembly chain.
///
/// Services are created lazily so that BLE/audio/ML resources are not allocated
/// until first use. Order matters for `inferencePipeline` — dependent services
/// must be accessed first so their lazy initialisers run before the pipeline
/// captures them.
public final class ServiceRegistry {

    // MARK: - Shared Instance
    public static let shared = ServiceRegistry()

    // MARK: - BLE Services
    public lazy var bluetoothDeviceScanner: BluetoothDeviceScannerProtocol =
        BluetoothDeviceScanner()

    public lazy var deviceConnectionManager: DeviceConnectionManagerProtocol =
        DeviceConnectionManager()

    // MARK: - Audio Services
    public lazy var audioRecorder: AudioRecorderProtocol =
        InternalMicRecorder()

    public lazy var audioConverter: AudioConverter =
        AudioConverter()

    public lazy var audioPlayer: AudioPlayerProtocol =
        AudioPlayer()

    public lazy var waveformGenerator: WaveformGeneratorProtocol =
        WaveformAnalyzer()

    // MARK: - ML Services
    public lazy var vadService: VADServiceProtocol =
        VADService()

    public lazy var languageDetection: LanguageDetectionProtocol =
        LanguageDetector(config: PipelineConfig(), whisperService: whisperASR)

    /// Concrete Whisper ASR instance, stored as the concrete type so it can be
    /// passed to InferencePipeline (which needs TranscriptionServiceProtocol)
    /// without a force-cast.
    private lazy var whisperASR: WhisperCoreMLService = WhisperCoreMLService()

    public lazy var asrService: ASRServiceProtocol = whisperASR

    /// Concrete Fallback ASR instance
    private lazy var fallbackASR: FallbackASRService = FallbackASRService()

    public lazy var diarizationService: DiarizationServiceProtocol =
        DiarizationService()

    /// Concrete LLM instance, stored as the concrete type so it can be passed
    /// to InferencePipeline (which needs SummarizationServiceProtocol).
    private lazy var llmCore: LLMService = LLMService()

    public lazy var llmService: LLMServiceProtocol = llmCore

    public lazy var inferencePipeline: InferencePipelineProtocol =
        InferencePipeline(
            vadService: vadService,
            languageDetector: languageDetection,
            transcriptionService: whisperASR,   // WhisperCoreMLService: TranscriptionServiceProtocol
            fallbackTranscriptionService: fallbackASR, // FallbackASRService: TranscriptionServiceProtocol
            diarizationService: diarizationService,
            summarizationService: llmCore        // LLMService: SummarizationServiceProtocol
        )

    // MARK: - Repository Services
    public lazy var recordingRepository: RecordingRepositoryProtocol =
        RecordingRepository()

    // MARK: - Initialization
    private init() {}
}
