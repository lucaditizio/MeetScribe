import Foundation

public final class WaveformPlaybackAssembly {
    public static func createModule(audioURL: URL) -> WaveformPlaybackViewInput {
        let audioPlayer = AudioPlayer()
        let waveformAnalyzer = WaveformAnalyzer()
        let interactor = WaveformPlaybackInteractor(
            audioPlayer: audioPlayer,
            waveformAnalyzer: waveformAnalyzer
        )
        interactor.configure(with: audioURL)
        
        let presenter = WaveformPlaybackPresenter(
            view: nil,
            interactor: interactor
        )
        
        let view = WaveformPlaybackView(presenter: presenter)
        presenter.view = view
        
        return view
    }
}
