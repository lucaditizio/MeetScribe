import Foundation
import FluidAudio

/// Speaker diarization service using FluidAudio's OfflineDiarizerManager
public final class DiarizationService: DiarizationServiceProtocol {
    private var diarizerManager: OfflineDiarizerManager?
    private let clusteringThreshold: Double
    private let minSpeakers: Int
    private let maxSpeakers: Int
    
    public init(
        clusteringThreshold: Double = 0.35,
        minSpeakers: Int = 1,
        maxSpeakers: Int = 8
    ) {
        self.clusteringThreshold = clusteringThreshold
        self.minSpeakers = minSpeakers
        self.maxSpeakers = maxSpeakers
    }
    
    public func diarize(audioData: Data, maxSpeakers: Int) async throws -> [SpeakerSegment] {
        let effectiveMaxSpeakers = min(maxSpeakers, self.maxSpeakers)
        
        ScribeLogger.info("Starting diarization with maxSpeakers: \(effectiveMaxSpeakers)", category: .ml)
        
        do {
            try await loadManager()
            
            guard let samples = convertToFloat32PCM(from: audioData) else {
                ScribeLogger.error("Invalid audio data format for diarization", category: .ml)
                nullifyManager()
                return fallbackSpeakerSegments()
            }
            
            ScribeLogger.debug("Audio converted to \(samples.count) samples", category: .ml)
            
            guard let result = try await diarizerManager?.process(audio: samples) else {
                ScribeLogger.error("Diarization process returned nil", category: .ml)
                nullifyManager()
                return fallbackSpeakerSegments()
            }
            
            ScribeLogger.info("Diarization completed with \(result.segments.count) segments", category: .ml)
            
            let segments = convertToSpeakerSegments(from: result, maxSpeakers: effectiveMaxSpeakers)
            
            nullifyManager()
            
            return segments
            
        } catch {
            ScribeLogger.error("Diarization failed: \(error.localizedDescription)", category: .ml)
            nullifyManager()
            return fallbackSpeakerSegments()
        }
    }
    
    private func loadManager() async throws {
        ScribeLogger.info("Initializing diarizer manager", category: .ml)
        
        do {
            let config = OfflineDiarizerConfig(clusteringThreshold: clusteringThreshold)
            diarizerManager = OfflineDiarizerManager(config: config)
            
            try await diarizerManager?.prepareModels()
            
            ScribeLogger.info("Diarizer manager initialized successfully", category: .ml)
            
        } catch {
            ScribeLogger.error("Failed to initialize diarizer manager: \(error.localizedDescription)", category: .ml)
            throw DiarizationError.managerInitializationFailed
        }
    }
    
    private func nullifyManager() {
        diarizerManager = nil
        ScribeLogger.debug("Diarizer manager nullified for memory management", category: .ml)
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
    
    private func convertToSpeakerSegments(from result: DiarizationResult, maxSpeakers: Int) -> [SpeakerSegment] {
        var segments: [SpeakerSegment] = []
        
        for segment in result.segments {
            let speakerId = "Speaker\(segment.speakerId)"
            let speakerName = "Speaker \(segment.speakerId)"
            
            let speakerSegment = SpeakerSegment(
                speakerId: speakerId,
                speakerName: speakerName,
                start: TimeInterval(segment.startTimeSeconds),
                end: TimeInterval(segment.endTimeSeconds),
                text: "",
                confidence: 1.0
            )
            
            segments.append(speakerSegment)
        }
        
        ScribeLogger.debug("Converted \(segments.count) diarization segments", category: .ml)
        
        return segments
    }
    
    private func fallbackSpeakerSegments() -> [SpeakerSegment] {
        ScribeLogger.warning("Using fallback: single speaker segment", category: .ml)
        
        let fallbackSegment = SpeakerSegment(
            speakerId: "Speaker1",
            speakerName: "Speaker 1",
            start: 0,
            end: 0,
            text: "",
            confidence: 0.0
        )
        
        return [fallbackSegment]
    }
}

// MARK: - Diarization Errors

enum DiarizationError: LocalizedError {
    case managerInitializationFailed
    
    var errorDescription: String? {
        switch self {
        case .managerInitializationFailed:
            return "Failed to initialize speaker diarization manager"
        }
    }
}
