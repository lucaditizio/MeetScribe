import Foundation
import AVFoundation

/// Assembly for RecordingDetailModule.
/// Accepts a shared RecordingRepositoryProtocol injected from AppAssembly.
public final class RecordingDetailAssembly {

    public static func createModule(
        recordingId: String,
        recordingRepository: RecordingRepositoryProtocol,
        audioPlayer: AudioPlayerProtocol
    ) -> RecordingDetailPresenter {
        let interactor = RecordingDetailInteractor(
            output: nil,
            recordingRepository: recordingRepository
        )
        let router = RecordingDetailRouter(viewController: nil)
        
        let waveformPresenter = WaveformPlaybackAssembly.createModule(
            recordingId: recordingId,
            recordingRepository: recordingRepository,
            audioPlayer: audioPlayer,
            waveformAnalyzer: WaveformAnalyzer()
        )
        
        let presenter = RecordingDetailPresenter(
            view: nil,
            interactor: interactor,
            router: router,
            waveformPresenter: waveformPresenter
        )

        interactor.obtainRecording(id: recordingId)

        return presenter
    }
}
