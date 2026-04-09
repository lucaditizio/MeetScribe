import Foundation
import Combine

/// Receives audio stream from BLE and decodes it
public final class AudioStreamReceiver {
    
    public var pcmAudioPublisher: AnyPublisher<[Float], Never> {
        pcmAudioSubject.eraseToAnyPublisher()
    }
    
    private let pcmAudioSubject = PassthroughSubject<[Float], Never>()
    private var decoder: OpusAudioDecoder?
    private var packetParser: SLinkPacketParser
    
    public init() {
        self.packetParser = SLinkPacketParser()
        do {
            self.decoder = try OpusAudioDecoder()
        } catch {
            ScribeLogger.error("Failed to create Opus decoder: \(error)", category: .audio)
        }
    }
    
    /// Feed raw BLE audio data
    public func feedAudioData(_ data: Data) {
        let packets = packetParser.feed(data)
        
        for packet in packets {
            decodeAndPublish(packet)
        }
    }
    
    private func decodeAndPublish(_ packet: SLinkPacket) {
        guard let decoder = decoder else { return }
        
        do {
            let pcmData = try decoder.decode(Data(packet.payload))
            pcmAudioSubject.send(pcmData)
        } catch {
            ScribeLogger.error("Decode error: \(error)", category: .audio)
        }
    }
}
