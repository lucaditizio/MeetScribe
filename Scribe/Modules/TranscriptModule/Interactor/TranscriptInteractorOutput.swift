import Foundation
import SwiftData

public protocol TranscriptInteractorOutput: AnyObject {
    func didObtainTranscriptSegments(_ segments: [SpeakerSegment])
    func didFailWithError(_ error: Error)
}
