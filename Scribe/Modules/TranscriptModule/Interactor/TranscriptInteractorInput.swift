import Foundation

public protocol TranscriptInteractorInput: AnyObject {
    func obtainTranscriptSegments()
    func renameSpeaker(from oldName: String, to newName: String)
}
