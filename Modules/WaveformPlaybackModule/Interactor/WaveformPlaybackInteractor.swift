import Foundation

public final class WaveformPlaybackInteractor: WaveformPlaybackInteractorInput {
    private weak var output: WaveformPlaybackInteractorOutput?
    private let audioPlayer: AudioPlayerProtocol
    private let waveformAnalyzer: WaveformAnalyzer
    private var audioURL: URL?
    private var currentSpeed: Float = 1.0
    
    private let speeds: [Float] = [1.0, 1.5, 2.0]
    private var currentSpeedIndex = 0
    
    public init(
        output: WaveformPlaybackInteractorOutput?,
        audioPlayer: AudioPlayerProtocol,
        waveformAnalyzer: WaveformAnalyzer
    ) {
        self.output = output
        self.audioPlayer = audioPlayer
        self.waveformAnalyzer = waveformAnalyzer
    }
    
    public func configureWith(audioURL: URL) {
        self.audioURL = audioURL
    }
    
    public func obtainWaveformData() {
        guard let url = audioURL else {
            output?.didFailWithError(WaveformPlaybackError.noAudioURL)
            return
        }
        
        Task {
            do {
                let bars = try await waveformAnalyzer.analyze(url: url)
                output?.didObtainWaveformData(bars)
            } catch {
                output?.didFailWithError(error)
            }
        }
    }
    
    public func playAudio() {
        audioPlayer.play()
        output?.didUpdatePlaybackState(isPlaying: true, currentTime: audioPlayer.currentTime)
    }
    
    public func pauseAudio() {
        audioPlayer.pause()
        output?.didUpdatePlaybackState(isPlaying: false, currentTime: audioPlayer.currentTime)
    }
    
    public func seekTo(_ time: TimeInterval) {
        audioPlayer.seek(to: time)
        output?.didUpdatePlaybackState(isPlaying: audioPlayer.isPlaying, currentTime: time)
    }
    
    public func cycleSpeed() {
        currentSpeedIndex = (currentSpeedIndex + 1) % speeds.count
        currentSpeed = speeds[currentSpeedIndex]
        audioPlayer.setSpeed(currentSpeed)
        output?.didUpdatePlaybackState(isPlaying: audioPlayer.isPlaying, currentTime: audioPlayer.currentTime)
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
