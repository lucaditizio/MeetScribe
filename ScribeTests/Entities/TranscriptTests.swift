import XCTest
@testable import Scribe

final class TranscriptTests: XCTestCase {
    func testSpeakerSegmentInitialization() {
        let segment = SpeakerSegment(
            speakerId: "1",
            speakerName: "Speaker 1",
            start: 0.0,
            end: 5.5,
            text: "Hello world",
            confidence: 0.95
        )
        
        XCTAssertEqual(segment.speakerId, "1")
        XCTAssertEqual(segment.speakerName, "Speaker 1")
        XCTAssertEqual(segment.text, "Hello world")
        XCTAssertEqual(segment.confidence, 0.95)
        XCTAssertNotNil(segment.id)
    }
    
    func testTranscriptInitialization() {
        let recordingId = UUID()
        let transcript = Transcript(
            recordingId: recordingId,
            fullText: "Hello world",
            detectedLanguage: "en"
        )
        
        XCTAssertEqual(transcript.recordingId, recordingId)
        XCTAssertEqual(transcript.fullText, "Hello world")
        XCTAssertEqual(transcript.detectedLanguage, "en")
        XCTAssertNotNil(transcript.id)
    }
}
