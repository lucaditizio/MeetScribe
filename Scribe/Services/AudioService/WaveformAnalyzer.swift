import Foundation
import AVFoundation
import CoreMedia

public final class WaveformAnalyzer {
    
    private enum Constants {
        static let minNormalizedValue: Float = 0.05
        static let maxNormalizedValue: Float = 1.0
        static let normalizationRange: Float = 0.95
    }
    
    public init() {}
    
    public func analyze(url: URL, barCount: Int = 50) async throws -> [AudioSample] {
        guard FileManager.default.fileExists(atPath: url.path) else {
            ScribeLogger.error("File not found at path: \(url.path)", category: .audio)
            throw WaveformAnalyzerError.fileNotFound(url.path)
        }
        
        ScribeLogger.debug("Starting waveform analysis for: \(url.lastPathComponent)", category: .audio)
        
        let asset = AVAsset(url: url)
        let reader = try AVAssetReader(asset: asset)
        
        guard let audioTrack = try await asset.loadTracks(withMediaType: .audio).first else {
            ScribeLogger.error("No audio track found in file: \(url.lastPathComponent)", category: .audio)
            throw WaveformAnalyzerError.noAudioTrack
        }
        
        let outputSettings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatLinearPCM),
            AVLinearPCMIsFloatKey: true,
            AVLinearPCMBitDepthKey: 32,
            AVLinearPCMIsBigEndianKey: false,
            AVLinearPCMIsNonInterleaved: true
        ]
        
        let output = AVAssetReaderTrackOutput(track: audioTrack, outputSettings: outputSettings)
        reader.add(output)
        
        guard reader.startReading() else {
            let error = reader.error ?? NSError(domain: "WaveformAnalyzer", code: -1)
            ScribeLogger.error("Failed to start reading: \(error.localizedDescription)", category: .audio)
            throw WaveformAnalyzerError.readerStartFailed(error)
        }
        
        var allSamples: [Float] = []
        var totalDuration: TimeInterval = 0
        
        while let sampleBuffer = output.copyNextSampleBuffer() {
            guard let dataBuffer = CMSampleBufferGetDataBuffer(sampleBuffer) else {
                continue
            }
            
            let dataLength = CMBlockBufferGetDataLength(dataBuffer)
            let sampleCountFloat = dataLength / MemoryLayout<Float>.size
            
            let presentationTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
            let timestamp = CMTimeGetSeconds(presentationTime)
            
            guard sampleCountFloat > 0 else { continue }
            var floatData = [Float](repeating: 0, count: sampleCountFloat)
            floatData.withUnsafeMutableBufferPointer { buffer in
                guard let baseAddress = buffer.baseAddress else { return }
                CMBlockBufferCopyDataBytes(dataBuffer, atOffset: 0, dataLength: dataLength, destination: baseAddress)
            }
            
            allSamples.append(contentsOf: floatData)
            totalDuration = timestamp + CMTimeGetSeconds(CMSampleBufferGetDuration(sampleBuffer))
        }
        
        reader.cancelReading()
        
        ScribeLogger.debug("Read \(allSamples.count) samples, duration: \(totalDuration)s", category: .audio)
        
        let downsampledSamples = downsample(samples: allSamples, to: barCount, duration: totalDuration)
        
        ScribeLogger.info("Waveform analysis complete: \(downsampledSamples.count) bars", category: .audio)
        
        return downsampledSamples
    }
    
    private func downsample(samples: [Float], to targetCount: Int, duration: TimeInterval) -> [AudioSample] {
        guard !samples.isEmpty else {
            ScribeLogger.warning("No samples to downsample", category: .audio)
            return []
        }
        
        guard targetCount > 0 else {
            ScribeLogger.warning("Invalid target count: \(targetCount)", category: .audio)
            return []
        }
        
        let binSize = max(1, samples.count / targetCount)
        var peaks: [Float] = []
        var timestamps: [TimeInterval] = []
        
        for i in stride(from: 0, to: samples.count, by: binSize) {
            let endIndex = min(i + binSize, samples.count)
            let binSamples = samples[i..<endIndex]
            
            let peak = binSamples.map { abs($0) }.max() ?? 0
            peaks.append(peak)
            
            let binProgress = Float(i) / Float(samples.count)
            timestamps.append(duration * TimeInterval(binProgress))
        }
        
        let normalizedPeaks = normalize(peaks: peaks)
        
        return zip(normalizedPeaks, timestamps).map { value, timestamp in
            AudioSample(value: value, timestamp: timestamp)
        }
    }
    
    private func normalize(peaks: [Float]) -> [Float] {
        guard !peaks.isEmpty else { return [] }
        
        let maxPeak = peaks.max() ?? 0
        let minPeak = peaks.min() ?? 0
        
        let range = maxPeak - minPeak
        guard range > 0 else {
            return peaks.map { _ in Constants.minNormalizedValue }
        }
        
        return peaks.map { peak in
            let normalized = (peak - minPeak) / range * Constants.normalizationRange + Constants.minNormalizedValue
            return min(max(normalized, Constants.minNormalizedValue), Constants.maxNormalizedValue)
        }
    }
}

public enum WaveformAnalyzerError: LocalizedError {
    case fileNotFound(String)
    case noAudioTrack
    case readerStartFailed(Error)
    case invalidFormat
    case readFailed(Error)
    
    public var errorDescription: String? {
        switch self {
        case .fileNotFound(let path):
            return "Audio file not found at path: \(path)"
        case .noAudioTrack:
            return "No audio track found in the file"
        case .readerStartFailed(let error):
            return "Failed to start asset reader: \(error.localizedDescription)"
        case .invalidFormat:
            return "Invalid audio format"
        case .readFailed(let error):
            return "Failed to read audio data: \(error.localizedDescription)"
        }
    }
}