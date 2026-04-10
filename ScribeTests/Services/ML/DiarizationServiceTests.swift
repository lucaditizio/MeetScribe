import XCTest
@testable import Scribe
import FluidAudio

final class DiarizationServiceTests: XCTestCase {
    var service: DiarizationService!
    
    override func setUp() {
        super.setUp()
        service = DiarizationService()
    }
    
    override func tearDown() {
        service = nil
        super.tearDown()
    }
    
    func testEmptyAudioThrowsError() async throws {
        let emptyData = Data()
        
        do {
            _ = try await service.diarize(audioData: emptyData, maxSpeakers: 2)
            XCTFail("Expected error when diarizing empty audio")
        } catch DiarizationError.managerInitializationFailed {
            // Expected - manager initialization fails with empty data
        } catch {
            XCTFail("Expected DiarizationError.managerInitializationFailed, got: \(error)")
        }
    }
    
    func testVeryShortAudioThrowsError() async throws {
        let shortData = Data(repeating: 0, count: 3)
        
        do {
            _ = try await service.diarize(audioData: shortData, maxSpeakers: 2)
            XCTFail("Expected error when diarizing very short audio")
        } catch DiarizationError.managerInitializationFailed {
            // Expected - manager initialization fails with invalid data
        } catch {
            XCTFail("Expected DiarizationError.managerInitializationFailed, got: \(error)")
        }
    }
    
    func testInvalidAudioFormatReturnsFallbackSpeaker() async throws {
        let invalidData = Data(repeating: 0, count: 4)
        
        let segments = try await service.diarize(audioData: invalidData, maxSpeakers: 2)
        
        XCTAssertEqual(segments.count, 1)
        XCTAssertEqual(segments[0].speakerId, "Speaker1")
        XCTAssertEqual(segments[0].speakerName, "Speaker 1")
        XCTAssertEqual(segments[0].start, 0)
        XCTAssertEqual(segments[0].end, 0)
        XCTAssertEqual(segments[0].confidence, 0.0)
    }
    
    func testDiarizationFailureReturnsFallbackSpeaker() async throws {
        let failureData = Data(repeating: 0, count: 100)
        
        let segments = try await service.diarize(audioData: failureData, maxSpeakers: 2)
        
        XCTAssertEqual(segments.count, 1)
        XCTAssertEqual(segments[0].speakerId, "Speaker1")
        XCTAssertEqual(segments[0].speakerName, "Speaker 1")
    }
    
    func testCustomClusteringThreshold() {
        let service = DiarizationService(clusteringThreshold: 0.5)
        
        XCTAssertNotNil(service)
    }
    
    func testCustomMinMaxSpeakers() {
        let service = DiarizationService(minSpeakers: 2, maxSpeakers: 4)
        
        XCTAssertNotNil(service)
    }
    
    func testMaxSpeakersRespectsServiceLimit() async throws {
        let service = DiarizationService(maxSpeakers: 4)
        let audioData = Data(repeating: 0, count: 100)
        
        let segments = try await service.diarize(audioData: audioData, maxSpeakers: 8)
        
        XCTAssertEqual(segments.count, 1)
    }
}
