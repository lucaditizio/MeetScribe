import Foundation

/// Represents a decoded audio sample for waveform visualization
/// This is NOT a SwiftData model - just a value type for processing
public struct AudioSample: Sendable {
    public let amplitude: Float
    public let timestamp: TimeInterval
    
    public init(amplitude: Float, timestamp: TimeInterval) {
        self.amplitude = amplitude
        self.timestamp = timestamp
    }
}

/// Collection of audio samples with helper methods
public struct AudioSampleBuffer: Sendable {
    public let samples: [AudioSample]
    public let duration: TimeInterval
    
    public init(samples: [AudioSample], duration: TimeInterval) {
        self.samples = samples
        self.duration = duration
    }
    
    /// Returns the maximum amplitude in the buffer
    public var maxAmplitude: Float {
        samples.map { $0.amplitude }.max() ?? 0.0
    }
    
    /// Returns samples downsampled to target count for visualization
    public func downsampled(to targetCount: Int) -> [AudioSample] {
        guard samples.count > targetCount else { return samples }
        
        let chunkSize = samples.count / targetCount
        return stride(from: 0, to: samples.count, by: chunkSize).map { index in
            samples[index]
        }
    }
}
