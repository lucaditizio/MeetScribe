import Foundation
import FluidAudio

/// Voice Activity Detection service using FluidAudio
public final class VADService: VADServiceProtocol {
    private var vadManager: VadManager?
    private let config: VADConfig
    
    public init(config: VADConfig = VADConfig()) {
        self.config = config
    }
    
    public func process(buffer: Data) -> Bool {
        guard let samples = convertToFloat32PCM(from: buffer) else {
            ScribeLogger.error("Invalid buffer format for VAD", category: .ml)
            return false
        }
        
        return detectSpeech(in: samples)
    }
    
    public func hasSpeech(audioURL: URL) async throws -> Bool {
        try await loadManager()
        
        let results = try await vadManager?.process(audioURL) ?? []
        
        let hasSpeech = results.contains { $0.isVoiceActive }
        
        nullifyManager()
        
        if hasSpeech {
            ScribeLogger.info("Speech detected in audio", category: .ml)
        } else {
            ScribeLogger.info("No speech detected in audio", category: .ml)
        }
        
        return hasSpeech
    }
    
    private func detectSpeech(in samples: [Float]) -> Bool {
        guard let manager = vadManager else {
            ScribeLogger.fault("VAD manager not initialized", category: .ml)
            return false
        }
        
        Task {
            do {
                let results = try await manager.process(samples)
                
                for result in results {
                    if result.isVoiceActive {
                        ScribeLogger.debug("Speech detected with probability: \(result.probability)", category: .ml)
                        break
                    }
                }
            } catch {
                ScribeLogger.warning("VAD inference failed: \(error.localizedDescription)", category: .ml)
            }
        }
        
        return false
    }
    
    private func loadManager() async throws {
        ScribeLogger.info("Initializing VAD manager", category: .ml)
        
        do {
            vadManager = try await VadManager(config: VadConfig(defaultThreshold: config.threshold))
            ScribeLogger.info("VAD manager initialized successfully", category: .ml)
        } catch {
            ScribeLogger.error("Failed to initialize VAD manager: \(error.localizedDescription)", category: .ml)
            throw VADError.managerInitializationFailed
        }
    }
    
    private func nullifyManager() {
        vadManager = nil
        ScribeLogger.debug("VAD manager nullified for memory management", category: .ml)
    }
    
    private func convertToFloat32PCM(from audioData: Data) -> [Float]? {
        guard audioData.count >= 4 else { return nil }
        
        let sampleCount = audioData.count / 4
        
        var samples: [Float] = []
        samples.reserveCapacity(sampleCount)
        
        audioData.withUnsafeBytes { pointer in
            guard let baseAddress = pointer.baseAddress else { return }
            let floatPointer = baseAddress.bindMemory(to: Float.self, capacity: sampleCount)
            for i in 0..<sampleCount {
                samples.append(floatPointer[i])
            }
        }
        
        return samples
    }
}

// MARK: - VAD Errors

enum VADError: LocalizedError {
    case managerInitializationFailed
    
    var errorDescription: String? {
        switch self {
        case .managerInitializationFailed:
            return "Failed to initialize Voice Activity Detection manager"
        }
    }
}
