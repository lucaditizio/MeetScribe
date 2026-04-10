import Foundation
import AVFoundation
import Combine

/// Audio player implementation wrapping AVAudioPlayer with reactive state
@objc public final class AudioPlayer: NSObject, AudioPlayerProtocol {
    // MARK: - Properties
    
    private var audioPlayer: AVAudioPlayer?
    private var currentRate: Float = 1.0
    
    private let playbackStateSubject = CurrentValueSubject<PlaybackState, Never>(.idle)
    private let currentTimeSubject = CurrentValueSubject<TimeInterval, Never>(0.0)
    
    public var playbackStatePublisher: AnyPublisher<PlaybackState, Never> {
        playbackStateSubject.eraseToAnyPublisher()
    }
    
    public var currentTimePublisher: AnyPublisher<TimeInterval, Never> {
        currentTimeSubject.eraseToAnyPublisher()
    }
    
    // MARK: - AudioPlayerProtocol Requirements
    
    public func load(url: URL) {
        ScribeLogger.info("Loading audio from URL", category: .audio)
        playbackStateSubject.send(.loading)
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.delegate = self
            audioPlayer?.prepareToPlay()
            
            currentTimeSubject.send(audioPlayer?.currentTime ?? 0.0)
            playbackStateSubject.send(.idle)
            
            ScribeLogger.info("Audio loaded successfully", category: .audio)
        } catch {
            ScribeLogger.error("Failed to load audio: \(error.localizedDescription)", category: .audio)
            playbackStateSubject.send(.error(error))
        }
    }
    
    public func play() {
        guard let player = audioPlayer else {
            ScribeLogger.warning("Cannot play: no audio loaded", category: .audio)
            return
        }
        
        // Cycle playback rate: 1.0x → 1.5x → 2.0x → 1.0x
        currentRate = nextPlaybackRate(from: currentRate)
        player.rate = currentRate
        
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.allowAirPlay, .allowBluetooth])
            try AVAudioSession.sharedInstance().setActive(true)
            
            player.play()
            playbackStateSubject.send(.playing)
            
            ScribeLogger.info("Playback started at \(currentRate)x speed", category: .audio)
        } catch {
            ScribeLogger.error("Failed to start playback: \(error.localizedDescription)", category: .audio)
            playbackStateSubject.send(.error(error))
        }
    }
    
    public func pause() {
        guard let player = audioPlayer else {
            ScribeLogger.warning("Cannot pause: no audio loaded", category: .audio)
            return
        }
        
        player.pause()
        playbackStateSubject.send(.paused)
        
        ScribeLogger.info("Playback paused", category: .audio)
    }
    
    public func seek(to time: TimeInterval) {
        guard let player = audioPlayer else {
            ScribeLogger.warning("Cannot seek: no audio loaded", category: .audio)
            return
        }
        
        player.currentTime = time
        currentTimeSubject.send(time)
        
        ScribeLogger.info("Seeked to \(time) seconds", category: .audio)
    }
    
    public func stop() {
        guard let player = audioPlayer else {
            ScribeLogger.warning("Cannot stop: no audio loaded", category: .audio)
            return
        }
        
        player.stop()
        player.currentTime = 0.0
        currentTimeSubject.send(0.0)
        playbackStateSubject.send(.idle)
        
        deactivateAudioSession()
        
        ScribeLogger.info("Playback stopped", category: .audio)
    }
    
    // MARK: - Skip Methods
    
    public func skipForward() {
        guard let player = audioPlayer else { return }
        
        let newTime = player.currentTime + 15.0
        let duration = player.duration
        
        if newTime >= duration {
            seek(to: duration)
        } else {
            seek(to: newTime)
        }
    }
    
    public func skipBackward() {
        guard let player = audioPlayer else { return }
        
        let newTime = player.currentTime - 15.0
        
        if newTime <= 0.0 {
            seek(to: 0.0)
        } else {
            seek(to: newTime)
        }
    }
    
    // MARK: - Private Methods
    
    private func nextPlaybackRate(from current: Float) -> Float {
        switch current {
        case 1.0:
            return 1.5
        case 1.5:
            return 2.0
        case 2.0:
            return 1.0
        default:
            return 1.0
        }
    }
    
    private func deactivateAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setActive(false)
            ScribeLogger.debug("Audio session deactivated", category: .audio)
        } catch {
            ScribeLogger.warning("Failed to deactivate audio session: \(error.localizedDescription)", category: .audio)
        }
    }
    
    // MARK: - Deinit
    
    deinit {
        stop()
        audioPlayer = nil
        ScribeLogger.debug("AudioPlayer deinitialized", category: .audio)
    }
}

// MARK: - AVAudioPlayerDelegate

extension AudioPlayer: AVAudioPlayerDelegate {
    public func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        if flag {
            ScribeLogger.info("Audio playback completed successfully", category: .audio)
            deactivateAudioSession()
            playbackStateSubject.send(.idle)
        } else {
            let error = NSError(domain: "AudioPlayer", code: -1, userInfo: [NSLocalizedDescriptionKey: "Playback failed"])
            ScribeLogger.error("Audio playback failed", category: .audio)
            playbackStateSubject.send(.error(error))
        }
    }
    
    public func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        let playbackError = error ?? NSError(domain: "AudioPlayer", code: -2, userInfo: [NSLocalizedDescriptionKey: "Decode error occurred"])
        ScribeLogger.error("Decode error: \(playbackError.localizedDescription)", category: .audio)
        playbackStateSubject.send(.error(playbackError))
    }
}
