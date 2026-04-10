import XCTest
@testable import Scribe

final class FallbackASRServiceTests: XCTestCase {
    private var service: FallbackASRService!
    private var config: PipelineConfig!
    
    override func setUp() {
        super.setUp()
        config = PipelineConfig()
        service = FallbackASRService(config: config)
    }
    
    override func tearDown() {
        service = nil
        config = nil
        super.tearDown()
    }
    
    func testEmptyAudioThrowsError() async {
        let emptyData = Data()
        
        do {
            _ = try await service.transcribe(audioData: emptyData, language: "en")
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(true, "Error thrown as expected")
        }
    }
    
    func testInsufficientSamplesThrowsError() async {
        let insufficientData = createMockAudioData(sampleCount: config.minASRSamples - 1)
        
        do {
            _ = try await service.transcribe(audioData: insufficientData, language: "en")
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(true, "Error thrown as expected")
        }
    }
    
    func testInvalidAudioFormatThrowsError() async {
        var samples = [Float](repeating: 0.0, count: 100)
        samples.append(0.0)
        let invalidData = Data(bytes: &samples, count: samples.count * MemoryLayout<Float>.size)
        
        do {
            _ = try await service.transcribe(audioData: invalidData, language: "en")
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(true, "Error thrown as expected")
        }
    }
    
    func testValidAudioDataTriesToLoadModel() async {
        let validData = createMockAudioData(sampleCount: config.minASRSamples)
        
        do {
            _ = try await service.transcribe(audioData: validData, language: "de")
            XCTFail("Expected error during model load")
        } catch {
            XCTAssertTrue(true, "Error thrown as expected")
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