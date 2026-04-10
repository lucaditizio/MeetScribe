import Foundation
import AVFoundation

public final class AudioConverter {
    
    private enum Constants {
        static let targetSampleRate: Double = 16000
    }
    
    public init() {}
    
    public func convertCAFToPCM(url: URL) async throws -> [Float] {
        guard FileManager.default.fileExists(atPath: url.path) else {
            ScribeLogger.error("CAF file not found at path: \(url.path)", category: .audio)
            throw AudioConverterError.fileNotFound(url.path)
        }
        
        let pathExtension = url.pathExtension.lowercased()
        guard pathExtension == "caf" else {
            ScribeLogger.error("Invalid file format: expected .caf, got .\(pathExtension)", category: .audio)
            throw AudioConverterError.invalidFormat("Expected CAF file, got .\(pathExtension)")
        }
        
        ScribeLogger.debug("Starting CAF to PCM conversion for: \(url.lastPathComponent)", category: .audio)
        
        var audioFile: AVAudioFile
        do {
            audioFile = try AVAudioFile(forReading: url)
        } catch {
            ScribeLogger.error("Failed to open audio file: \(error.localizedDescription)", category: .audio)
            throw AudioConverterError.fileOpenFailed(error)
        }
        
        let format = audioFile.processingFormat
        let frameCount = UInt32(audioFile.length)
        
        ScribeLogger.debug("Audio format: \(format.description), frames: \(frameCount)", category: .audio)
        
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else {
            ScribeLogger.error("Failed to create PCM buffer", category: .audio)
            throw AudioConverterError.bufferCreationFailed
        }
        
        do {
            try audioFile.read(into: buffer)
        } catch {
            ScribeLogger.error("Failed to read audio data: \(error.localizedDescription)", category: .audio)
            throw AudioConverterError.readFailed(error)
        }
        
        guard let channelData = buffer.floatChannelData else {
            ScribeLogger.error("Failed to access float channel data", category: .audio)
            throw AudioConverterError.noChannelData
        }
        
        let sampleCount = Int(buffer.frameLength)
        var floatSamples = [Float](repeating: 0, count: sampleCount)
        
        let dataPointer = channelData[0]
        floatSamples.withUnsafeMutableBufferPointer { bufferPointer in
            dataPointer.withMemoryRebound(to: Float.self, capacity: sampleCount) { sourcePointer in
                bufferPointer.baseAddress?.initialize(from: sourcePointer, count: sampleCount)
            }
        }
        
        ScribeLogger.info("CAF conversion complete: \(sampleCount) samples extracted", category: .audio)
        
        return floatSamples
    }
    
    public func convertCAFToPCMForASR(url: URL) async throws -> [Float] {
        let rawSamples = try await convertCAFToPCM(url: url)
        
        let audioFile = try AVAudioFile(forReading: url)
        let sourceSampleRate = audioFile.processingFormat.sampleRate
        
        if sourceSampleRate == Constants.targetSampleRate {
            ScribeLogger.debug("Audio already at target sample rate: \(Constants.targetSampleRate)Hz", category: .audio)
            return rawSamples
        }
        
        ScribeLogger.debug("Resampling from \(sourceSampleRate)Hz to \(Constants.targetSampleRate)Hz", category: .audio)
        
        let resampledSamples = resample(
            samples: rawSamples,
            sourceRate: sourceSampleRate,
            targetRate: Constants.targetSampleRate
        )
        
        ScribeLogger.info("Resampling complete: \(rawSamples.count) -> \(resampledSamples.count) samples", category: .audio)
        
        return resampledSamples
    }
    
    private func resample(samples: [Float], sourceRate: Double, targetRate: Double) -> [Float] {
        guard sourceRate > 0, targetRate > 0, !samples.isEmpty else {
            return samples
        }
        
        let ratio = sourceRate / targetRate
        let targetCount = Int(Double(samples.count) / ratio)
        
        guard targetCount > 0 else {
            return samples
        }
        
        var resampled = [Float]()
        resampled.reserveCapacity(targetCount)
        
        for i in 0..<targetCount {
            let sourceIndex = Double(i) * ratio
            let lowerIndex = Int(sourceIndex)
            let upperIndex = min(lowerIndex + 1, samples.count - 1)
            let fraction = Float(sourceIndex - Double(lowerIndex))
            
            let interpolated = samples[lowerIndex] * (1 - fraction) + samples[upperIndex] * fraction
            resampled.append(interpolated)
        }
        
        return resampled
    }
}

public enum AudioConverterError: LocalizedError {
    case fileNotFound(String)
    case invalidFormat(String)
    case fileOpenFailed(Error)
    case bufferCreationFailed
    case readFailed(Error)
    case noChannelData
    case conversionFailed(Error)
    
    public var errorDescription: String? {
        switch self {
        case .fileNotFound(let path):
            return "CAF file not found at path: \(path)"
        case .invalidFormat(let message):
            return "Invalid audio format: \(message)"
        case .fileOpenFailed(let error):
            return "Failed to open audio file: \(error.localizedDescription)"
        case .bufferCreationFailed:
            return "Failed to create audio buffer"
        case .readFailed(let error):
            return "Failed to read audio data: \(error.localizedDescription)"
        case .noChannelData:
            return "No channel data available in audio buffer"
        case .conversionFailed(let error):
            return "Audio conversion failed: \(error.localizedDescription)"
        }
    }
}