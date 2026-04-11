import Foundation
import Combine

public final class WaveformPlaybackInteractor: WaveformPlaybackInteractorInput {
    private weak var output: WaveformPlaybackInteractorOutput?
    private let audioPlayer: AudioPlayerProtocol
    private let waveformAnalyzer: WaveformAnalyzerProtocol
    private var audioURL: URL?
    private var currentSpeed: Float = 1.0
    
    private let speeds: [Float] = [1.0, 1.5, 2.0]
    private var currentSpeedIndex = 0
    
    public init(
        output: WaveformPlaybackInteractorOutput?,
        audioPlayer: AudioPlayerProtocol,
        waveformAnalyzer: WaveformAnalyzerProtocol
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
        output?.didUpdatePlaybackState(isPlaying: true, currentTime: 0)
    }
    
    public func pauseAudio() {
        audioPlayer.pause()
        output?.didUpdatePlaybackState(isPlaying: false, currentTime: 0)
    }
    
    public func seekTo(_ time: TimeInterval) {
        audioPlayer.seek(to: time)
        output?.didUpdatePlaybackState(isPlaying: true, currentTime: time)
    }
    
    public func cycleSpeed() {
        currentSpeedIndex = (currentSpeedIndex + 1) % speeds.count
        currentSpeed = speeds[currentSpeedIndex]
        output?.didUpdatePlaybackState(isPlaying: true, currentTime: 0)
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
