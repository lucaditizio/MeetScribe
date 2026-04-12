import Foundation
import Combine

public final class WaveformPlaybackInteractor: WaveformPlaybackInteractorInput {
    public weak var output: WaveformPlaybackInteractorOutput?
    private let audioPlayer: AudioPlayerProtocol
    private let waveformAnalyzer: WaveformAnalyzerProtocol
    private let recordingRepository: RecordingRepositoryProtocol
    private var recordingId: String?
    private var audioURL: URL?
    private var currentSpeed: Float = 1.0
    
    private let speeds: [Float] = [1.0, 1.5, 2.0]
    private var currentSpeedIndex = 0
    
    // Playback state syncing
    private var isPlaying: Bool = false
    private var lastTime: TimeInterval = 0
    private var cancellables = Set<AnyCancellable>()
    
    public init(
        output: WaveformPlaybackInteractorOutput?,
        audioPlayer: AudioPlayerProtocol,
        waveformAnalyzer: WaveformAnalyzerProtocol,
        recordingRepository: RecordingRepositoryProtocol
    ) {
        self.output = output
        self.audioPlayer = audioPlayer
        self.waveformAnalyzer = waveformAnalyzer
        self.recordingRepository = recordingRepository
        
        setupSubscriptions()
    }
    
    private func setupSubscriptions() {
        audioPlayer.playbackStatePublisher
            .receive(on: RunLoop.main)
            .sink { [weak self] state in
                guard let self = self else { return }
                switch state {
                case .playing: self.isPlaying = true
                case .idle, .loading, .paused, .error: self.isPlaying = false
                }
                self.output?.didUpdatePlaybackState(isPlaying: self.isPlaying, currentTime: self.lastTime)
            }
            .store(in: &cancellables)
            
        audioPlayer.currentTimePublisher
            .receive(on: RunLoop.main)
            .sink { [weak self] time in
                guard let self = self else { return }
                self.lastTime = time
                self.output?.didUpdatePlaybackState(isPlaying: self.isPlaying, currentTime: self.lastTime)
            }
            .store(in: &cancellables)
    }
    
    public func configureWith(recordingId: String) {
        self.recordingId = recordingId
    }
    
    public func obtainWaveformData() {
        guard let idString = recordingId, let uuid = UUID(uuidString: idString) else {
            output?.didFailWithError(WaveformPlaybackError.noAudioURL)
            return
        }
        
        Task { @MainActor in
            do {
                guard let recording = try await recordingRepository.fetch(by: uuid) else {
                    output?.didFailWithError(WaveformPlaybackError.noAudioURL)
                    return
                }
                
                let documentPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                let url = documentPath.appendingPathComponent(recording.fileName)
                self.audioURL = url
                
                // Publish duration from recording
                self.output?.didUpdateDuration(recording.duration)
                
                // LOAD AUDIO FILE INTO PLAYER!
                self.audioPlayer.load(url: url)
                
                let samples = try await waveformAnalyzer.analyze(url: url, barCount: 50)
                let bars = samples.map { $0.value }
                output?.didObtainWaveformData(bars)
            } catch {
                output?.didFailWithError(error)
            }
        }
    }
    
    public func playAudio() {
        audioPlayer.play()
    }
    
    public func pauseAudio() {
        audioPlayer.pause()
    }
    
    public func seekTo(_ time: TimeInterval) {
        audioPlayer.seek(to: time)
    }
    
    public func cycleSpeed() {
        currentSpeedIndex = (currentSpeedIndex + 1) % speeds.count
        currentSpeed = speeds[currentSpeedIndex]
        audioPlayer.setRate(currentSpeed)
        output?.didUpdatePlaybackState(isPlaying: self.isPlaying, currentTime: self.lastTime)
    }
}

public enum WaveformPlaybackError: LocalizedError {
    case noAudioURL
    
    public var errorDescription: String? {
        switch self {
        case .noAudioURL:
            return "No audio URL configured"
        }
    }
}
