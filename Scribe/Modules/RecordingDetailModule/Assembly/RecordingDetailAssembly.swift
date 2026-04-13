import Foundation
import AVFoundation

/// Assembly for RecordingDetailModule.
/// Accepts a shared RecordingRepositoryProtocol injected from AppAssembly.
public final class RecordingDetailAssembly {

    public static func createModule(
        recordingId: String,
        recordingRepository: RecordingRepositoryProtocol,
        audioPlayer: AudioPlayerProtocol
    ) -> RecordingDetailView {
        let router = RecordingDetailRouter(viewController: nil, appAssembly: .shared)
        
        let interactor = RecordingDetailInteractor(
            output: nil,
            recordingRepository: recordingRepository
        )
        
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
        
        interactor.output = presenter  // Wire the output!
        
        interactor.obtainRecording(id: recordingId)

        return RecordingDetailView(presenter: presenter, router: router)
    }
}
