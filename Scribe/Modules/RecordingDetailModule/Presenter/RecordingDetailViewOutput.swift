import Foundation

public protocol RecordingDetailViewOutput: AnyObject {
    func didTriggerViewReady()
    func didTapPlayPause()
    func didTapSkipForward()
    func didTapSkipBackward()
    func didSelectTab(_ tab: RecordingDetailTab)
    func didTapGenerateTranscript()
}
