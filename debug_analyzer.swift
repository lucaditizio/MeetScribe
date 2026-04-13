import Foundation
import AVFoundation

let args = CommandLine.arguments

func test() async {
    let url = URL(fileURLWithPath: "test.m4a")
    let asset = AVURLAsset(url: url)
    
    do {
        let tracks = try await asset.loadTracks(withMediaType: .audio)
        guard let audioTrack = tracks.first else {
            print("No audio track")
            return
        }
        
        let reader = try AVAssetReader(asset: asset)
        let outputSettings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatLinearPCM),
            AVLinearPCMIsFloatKey: true,
            AVLinearPCMBitDepthKey: 32,
            AVLinearPCMIsBigEndianKey: false,
            AVLinearPCMIsNonInterleaved: true
        ]
        
        // Let's see if this throws
        let output = AVAssetReaderTrackOutput(track: audioTrack, outputSettings: outputSettings)
        reader.add(output)
        
        if reader.startReading() {
            var allSamples: [Float] = []
            while let sampleBuffer = output.copyNextSampleBuffer() {
                guard let dataBuffer = CMSampleBufferGetDataBuffer(sampleBuffer) else { continue }
                let dataLength = CMBlockBufferGetDataLength(dataBuffer)
                let sampleCountFloat = dataLength / MemoryLayout<Float>.size
                guard sampleCountFloat > 0 else { continue }
                var floatData = [Float](repeating: 0, count: sampleCountFloat)
                 floatData.withUnsafeMutableBufferPointer { buffer in
                    guard let baseAddress = buffer.baseAddress else { return }
                    CMBlockBufferCopyDataBytes(dataBuffer, atOffset: 0, dataLength: dataLength, destination: baseAddress)
                }
                allSamples.append(contentsOf: floatData)
            }
            print("Samples: \(allSamples.count)")
        } else {
            print("Reader failed: \(String(describing: reader.error))")
        }
    } catch {
        print("Catch: \(error)")
    }
}

Task {
    await test()
    exit(0)
}
RunLoop.main.run()
