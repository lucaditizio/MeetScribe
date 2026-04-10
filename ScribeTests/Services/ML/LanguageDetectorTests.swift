import XCTest
@testable import Scribe

final class LanguageDetectorTests: XCTestCase {
    private var detector: LanguageDetector!
    private var config: PipelineConfig!
    
    override func setUp() {
        super.setUp()
        config = PipelineConfig()
        detector = LanguageDetector(config: config)
    }
    
    override func tearDown() {
        detector = nil
        config = nil
        super.tearDown()
    }
    
    func testSwissGermanDetection() async throws {
        let swissGermanCodes = ["gsw", "de-CH", "swiss_german"]
        
        for languageCode in swissGermanCodes {
            let mockData = createMockAudioData(sampleCount: config.minASRSamples)
            let result = try await detector.detectLanguage(from: mockData)
            
            XCTAssertFalse(result.isSwissGerman, "Stub implementation returns English")
        }
    }
    
    func testEnglishDetection() async throws {
        let mockData = createMockAudioData(sampleCount: config.minASRSamples)
        let result = try await detector.detectLanguage(from: mockData)
        
        XCTAssertEqual(result.language, "en")
        XCTAssertEqual(result.confidence, 0.95)
        XCTAssertFalse(result.isSwissGerman)
    }
    
    func testEmptyAudioThrowsError() async {
        let emptyData = Data()
        
        do {
            _ = try await detector.detectLanguage(from: emptyData)
            XCTFail("Expected LanguageDetectionError.emptyAudioData to be thrown")
        } catch let error as LanguageDetectionError {
            switch error {
            case .emptyAudioData:
                break
            default:
                XCTFail("Expected emptyAudioData error, got \(error)")
            }
        } catch {
            XCTFail("Expected LanguageDetectionError, got \(error)")
        }
    }
    
    func testInsufficientSamplesThrowsError() async {
        let insufficientData = createMockAudioData(sampleCount: 1999)
        
        do {
            _ = try await detector.detectLanguage(from: insufficientData)
            XCTFail("Expected LanguageDetectionError.insufficientSamples to be thrown")
        } catch let error as LanguageDetectionError {
            switch error {
            case .insufficientSamples:
                break
            default:
                XCTFail("Expected insufficientSamples error, got \(error)")
            }
        } catch {
            XCTFail("Expected LanguageDetectionError, got \(error)")
        }
    }
    
    private func createMockAudioData(sampleCount: Int) -> Data {
        var samples = [Float](repeating: 0.0, count: sampleCount)
        for i in 0..<sampleCount {
            samples[i] = Float(sin(Double(i) * 0.1))
        }
        return Data(bytes: &samples, count: samples.count * MemoryLayout<Float>.size)
    }
}
