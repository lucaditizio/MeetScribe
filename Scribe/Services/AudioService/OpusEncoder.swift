import Foundation
import Opus

/// Encodes PCM audio to Opus packets
public final class OpusEncoder {
    private var encoder: OpaquePointer?
    private let sampleRate: Int32
    private let channels: Int
    private let frameSize: Int
    private let maxPacketSize: Int
    
    public init(
        sampleRate: Int32 = 16000,
        channels: Int = 1,
        frameSize: Int = 320
    ) throws {
        self.sampleRate = sampleRate
        self.channels = channels
        self.frameSize = frameSize
        self.maxPacketSize = 4000
        
        var error: Int32 = 0
        encoder = opus_encoder_create(sampleRate, Int32(channels), OPUS_APPLICATION_AUDIO, &error)
        
        guard error == OPUS_OK, encoder != nil else {
            throw OpusEncoderError.encoderInitializationFailed
        }
        
        ScribeLogger.info("OpusEncoder initialized - \(sampleRate)Hz, \(channels)ch, frameSize: \(frameSize)", category: .audio)
    }
    
    deinit {
        if let encoder = encoder {
            opus_encoder_destroy(encoder)
        }
    }
    
    /// Encode Float32 PCM buffer to Opus packet
    public func encode(_ pcmBuffer: [Float]) throws -> Data {
        guard let encoder = encoder else {
            throw OpusEncoderError.encoderNotInitialized
        }
        
        let expectedSamples = frameSize * channels
        guard pcmBuffer.count == expectedSamples else {
            ScribeLogger.error("Invalid buffer size: \(pcmBuffer.count), expected: \(expectedSamples)", category: .audio)
            throw OpusEncoderError.invalidBufferSize(expected: expectedSamples, actual: pcmBuffer.count)
        }
        
        var outputBuffer = [UInt8](repeating: 0, count: maxPacketSize)
        
        let encodedBytes = opus_encode_float(
            encoder,
            pcmBuffer,
            Int32(frameSize),
            &outputBuffer,
            Int32(maxPacketSize)
        )
        
        guard encodedBytes > 0 else {
            let errorMessage = errorString(for: encodedBytes)
            ScribeLogger.error("Opus encoding failed: \(errorMessage)", category: .audio)
            throw OpusEncoderError.encodingFailed(errorCode: Int(encodedBytes))
        }
        
        return Data(outputBuffer.prefix(Int(encodedBytes)))
    }
    
    // MARK: - Private Helpers
    
    private func errorString(for errorCode: Int32) -> String {
        switch errorCode {
        case OPUS_OK:
            return "OK"
        case OPUS_BAD_ARG:
            return "Bad argument"
        case OPUS_BUFFER_TOO_SMALL:
            return "Buffer too small"
        case OPUS_INTERNAL_ERROR:
            return "Internal error"
        case OPUS_INVALID_PACKET:
            return "Invalid packet"
        case OPUS_UNIMPLEMENTED:
            return "Unimplemented"
        case OPUS_INVALID_STATE:
            return "Invalid state"
        case OPUS_ALLOC_FAIL:
            return "Allocation failed"
        default:
            return "Unknown error (\(errorCode))"
        }
    }
}

// MARK: - Errors

public enum OpusEncoderError: Error {
    case encoderInitializationFailed
    case encoderNotInitialized
    case invalidBufferSize(expected: Int, actual: Int)
    case encodingFailed(errorCode: Int)
}

extension OpusEncoderError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .encoderInitializationFailed:
            return "Failed to initialize Opus encoder"
        case .encoderNotInitialized:
            return "Opus encoder not initialized"
        case .invalidBufferSize(let expected, let actual):
            return "Invalid buffer size: expected \(expected), got \(actual)"
        case .encodingFailed(let errorCode):
            return "Opus encoding failed with error code: \(errorCode)"
        }
    }
}

// MARK: - Convenience Factory

extension OpusEncoder {
    /// Create an encoder with default audio configuration
    public static func makeDefault() throws -> OpusEncoder {
        let config = AudioConfig()
        return try OpusEncoder(
            sampleRate: Int32(config.sampleRate),
            channels: config.channelCount,
            frameSize: config.frameSize
        )
    }
}