import Foundation
import SwiftData

public protocol TranscriptViewInput: AnyObject {
    func displayTranscriptSegments(_ segments: [SpeakerSegment])
    func displayError(_ error: Error)
}
