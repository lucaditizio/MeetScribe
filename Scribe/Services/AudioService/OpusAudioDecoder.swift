import Foundation
import Opus

/// Decodes Opus audio to PCM for playback
public final class OpusAudioDecoder {
    private var decoder: OpaquePointer?
    private let sampleRate: Int32
    private let channels: Int
    
    public init(sampleRate: Int32 = 16000, channels: Int = 1) throws {
        self.sampleRate = sampleRate
        self.channels = channels
        
        var error: Int32 = 0
        decoder = opus_decoder_create(sampleRate, Int32(channels), &error)
        
        guard error == OPUS_OK, decoder != nil else {
            throw AudioError.decoderInitializationFailed
        }
    }
    
    deinit {
        if let decoder = decoder {
            opus_decoder_destroy(decoder)
        }
    }
    
    /// Decode Opus packet to PCM
    public func decode(_ opusData: Data) throws -> [Float] {
        guard let decoder = decoder else {
            throw AudioError.decoderNotInitialized
        }
        
        let maxFrameSize = 5760 // 120ms at 48kHz
        var pcmData = [Float](repeating: 0, count: maxFrameSize * channels)
        
        let frameCount = opus_decode_float(
            decoder,
            [UInt8](opusData),
            Int32(opusData.count),
            &pcmData,
            Int32(maxFrameSize),
            0
        )
        
        guard frameCount > 0 else {
            throw AudioError.decodeFailed
        }
        
        return Array(pcmData.prefix(Int(frameCount) * channels))
    }
}

public enum AudioError: Error {
    case decoderInitializationFailed
    case decoderNotInitialized
    case decodeFailed
}
