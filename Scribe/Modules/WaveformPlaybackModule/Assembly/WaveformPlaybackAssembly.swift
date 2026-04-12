import Foundation

/// Assembly for WaveformPlaybackModule.
/// Accepts real audio services injected from AppAssembly/ServiceRegistry.
public final class WaveformPlaybackAssembly {

    public static func createModule(
        recordingId: String,
        recordingRepository: RecordingRepositoryProtocol,
        audioPlayer: AudioPlayerProtocol,
        waveformAnalyzer: WaveformAnalyzerProtocol
    ) -> WaveformPlaybackPresenter {
        let interactor = WaveformPlaybackInteractor(
            output: nil,
            audioPlayer: audioPlayer,
            waveformAnalyzer: waveformAnalyzer,
            recordingRepository: recordingRepository
        )
        let presenter = WaveformPlaybackPresenter(view: nil, interactor: interactor)
        interactor.output = presenter
        
        // Wire the interactor to the presenter for output
        interactor.configureWith(recordingId: recordingId)
        
        return presenter
    }
}
