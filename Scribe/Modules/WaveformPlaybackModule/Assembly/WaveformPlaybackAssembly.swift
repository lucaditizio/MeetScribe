import Foundation

/// Assembly for WaveformPlaybackModule.
/// Accepts real audio services injected from AppAssembly/ServiceRegistry.
public final class WaveformPlaybackAssembly {

    public static func createModule(
        audioPlayer: AudioPlayerProtocol,
        waveformAnalyzer: WaveformAnalyzerProtocol
    ) -> WaveformPlaybackPresenter {
        let interactor = WaveformPlaybackInteractor(
            output: nil,
            audioPlayer: audioPlayer,
            waveformAnalyzer: waveformAnalyzer
        )
        let presenter = WaveformPlaybackPresenter(view: nil, interactor: interactor)
        return presenter
    }
}
