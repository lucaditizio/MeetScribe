import Foundation
import AVFoundation

func test() async {
    let url = URL(fileURLWithPath: "test.m4a")
    let asset = AVURLAsset(url: url)
    var totalDuration: TimeInterval = 0
    do {
        let track = try await asset.loadTracks(withMediaType: .audio).first!
        let output = AVAssetReaderTrackOutput(track: track, outputSettings: [
            AVFormatIDKey: Int(kAudioFormatLinearPCM),
            AVLinearPCMIsFloatKey: true,
            AVLinearPCMBitDepthKey: 32,
            AVLinearPCMIsBigEndianKey: false,
            AVLinearPCMIsNonInterleaved: true
        ])
        let reader = try AVAssetReader(asset: asset)
        reader.add(output)
        if reader.startReading() {
            while let buffer = output.copyNextSampleBuffer() {
                let duration = CMSampleBufferGetDuration(buffer)
                print("Duration numeric? \(CMTIME_IS_NUMERIC(duration)) - val: \(CMTimeGetSeconds(duration))")
                let pts = CMSampleBufferGetPresentationTimeStamp(buffer)
                totalDuration = CMTimeGetSeconds(pts) + CMTimeGetSeconds(duration)
                break
            }
        }
        print("Total Duration: \(totalDuration)")
    } catch { print(error) }
}
Task { await test(); exit(0) }
RunLoop.main.run()
