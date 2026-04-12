import Foundation
import AVFoundation

public final class AudioConverter {
    
    private enum Constants {
        static let targetSampleRate: Double = 16000
    }
    
    public init() {}
    
    public func sampleRate(of url: URL) throws -> Double {
        guard FileManager.default.fileExists(atPath: url.path) else {
            ScribeLogger.error("Audio file not found at path: \(url.path)", category: .audio)
            throw AudioConverterError.fileNotFound(url.path)
        }
        
        do {
            let audioFile = try AVAudioFile(forReading: url)
            let sampleRate = audioFile.processingFormat.sampleRate
            ScribeLogger.debug("Detected sample rate: \(sampleRate)Hz for \(url.lastPathComponent)", category: .audio)
            return sampleRate
        } catch {
            ScribeLogger.error("Failed to detect sample rate: \(error.localizedDescription)", category: .audio)
            throw AudioConverterError.sampleRateDetectionFailed(error)
        }
    }
    
    public func convertTo16kHzIfNeeded(sourceURL: URL) async throws -> URL {
        let sourceRate = try sampleRate(of: sourceURL)
        
        if sourceRate == Constants.targetSampleRate {
            ScribeLogger.debug("Source already at 16kHz, skipping conversion", category: .audio)
            return sourceURL
        }
        
        ScribeLogger.info("Converting \(Int(sourceRate))Hz → 16kHz for \(sourceURL.lastPathComponent)", category: .audio)
        return try await convertTo16kHz(sourceURL: sourceURL)
    }
    
    private func convertTo16kHz(sourceURL: URL) async throws -> URL {
        guard FileManager.default.fileExists(atPath: sourceURL.path) else {
            throw AudioConverterError.fileNotFound(sourceURL.path)
        }
        
        let sourceFile = try AVAudioFile(forReading: sourceURL)
        let sourceFormat = sourceFile.processingFormat
        let frameCount = AVAudioFrameCount(sourceFile.length)
        
        guard let targetFormat = AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: Constants.targetSampleRate,
            channels: 1,
            interleaved: false
        ) else {
            throw AudioConverterError.conversionFailed(NSError(domain: "AudioConverter", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to create target audio format"]))
        }
        
        guard let sourceBuffer = AVAudioPCMBuffer(pcmFormat: sourceFormat, frameCapacity: frameCount) else {
            throw AudioConverterError.bufferCreationFailed
        }
        
        try sourceFile.read(into: sourceBuffer)
        
        let outputURL = generateOutputURL(for: sourceURL, suffix: "_16kHz")
        
        guard let outputFile = try? AVAudioFile(
            forWriting: outputURL,
            settings: targetFormat.settings,
            commonFormat: .pcmFormatFloat32,
            interleaved: false
        ) else {
            throw AudioConverterError.conversionFailed(NSError(domain: "AudioConverter", code: -2, userInfo: [NSLocalizedDescriptionKey: "Failed to create output audio file"]))
        }
        
        guard let converter = AVAudioConverter(from: sourceFormat, to: targetFormat) else {
            throw AudioConverterError.conversionFailed(NSError(domain: "AudioConverter", code: -3, userInfo: [NSLocalizedDescriptionKey: "Failed to create audio converter"]))
        }
        
        let outputFrameCapacity = AVAudioFrameCount(Double(frameCount) * Constants.targetSampleRate / sourceFormat.sampleRate)
        guard let outputBuffer = AVAudioPCMBuffer(pcmFormat: targetFormat, frameCapacity: outputFrameCapacity) else {
            throw AudioConverterError.bufferCreationFailed
        }
        
        var error: NSError?
        let status = converter.convert(to: outputBuffer, error: &error) { inNumPackets, outStatus in
            outStatus.pointee = .haveData
            return sourceBuffer
        }
        
        if status == .error || error != nil {
            throw AudioConverterError.conversionFailed(error ?? NSError(domain: "AudioConverter", code: -4, userInfo: [NSLocalizedDescriptionKey: "Conversion failed with unknown error"]))
        }
        
        do {
            try outputFile.write(from: outputBuffer)
        } catch {
            throw AudioConverterError.writeFailed(error)
        }
        
        ScribeLogger.info("Conversion complete: \(outputURL.lastPathComponent)", category: .audio)
        return outputURL
    }
    
    private func generateOutputURL(for sourceURL: URL, suffix: String) -> URL {
        let directory = sourceURL.deletingLastPathComponent()
        let filename = sourceURL.deletingPathExtension().lastPathComponent
        let ext = sourceURL.pathExtension
        return directory.appendingPathComponent("\(filename)\(suffix).\(ext)")
    }
    
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
    case sampleRateDetectionFailed(Error?)
    case writeFailed(Error)
    
    public var errorDescription: String? {
        switch self {
        case .fileNotFound(let path):
            return "Audio file not found at path: \(path)"
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
        case .sampleRateDetectionFailed(let error):
            if let error = error {
                return "Failed to detect sample rate: \(error.localizedDescription)"
            }
            return "Failed to detect sample rate"
        case .writeFailed(let error):
            return "Failed to write audio file: \(error.localizedDescription)"
        }
    }
}