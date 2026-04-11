import Foundation

public protocol TranscriptViewOutput: AnyObject {
    func didTriggerViewReady()
    func didTapSpeaker(speakerId: String)
}
