import XCTest
@testable import Scribe

final class ConfigTests: XCTestCase {
    func testPipelineConfigValues() {
        let config = PipelineConfig()
        
        XCTAssertEqual(config.swissGermanWhisperURL, "jlnslv/whisper-large-v3-turbo-swiss-german-coreml")
        XCTAssertEqual(config.diarizationClusteringThreshold, 0.35)
        XCTAssertEqual(config.minSpeakers, 1)
        XCTAssertEqual(config.maxSpeakers, 8)
        XCTAssertEqual(config.singlePassThreshold, 25_000)
        XCTAssertEqual(config.chunkSize, 12_000)
        XCTAssertEqual(config.chunkOverlap, 1_200)
        XCTAssertEqual(config.llmModelFileName, "Llama-3.2-3B-Instruct-Q4_K_M.gguf")
        XCTAssertEqual(config.stageTimeout, 60)
        XCTAssertEqual(config.minASRSamples, 8000)
        XCTAssertFalse(config.llmModelDownloadURL.isEmpty)
    }

    func testAudioConfigValues() {
        let config = AudioConfig()
        
        XCTAssertEqual(config.sampleRate, 16_000)
        XCTAssertEqual(config.channelCount, 1)
        XCTAssertEqual(config.frameSize, 320)
        XCTAssertEqual(config.fileExtension, "caf")
        XCTAssertEqual(config.formatHint, "opus")
        XCTAssertEqual(config.internalMicSampleRate, 48_000)
        XCTAssertEqual(config.internalMicFormat, "m4a")
    }

    func testBluetoothConfigValues() {
        let config = BluetoothConfig()
        
        XCTAssertEqual(config.serviceUUID, "E49A3001-F69A-11E8-8EB2-F2801F1B9FD1")
        XCTAssertEqual(config.audioCharacteristicUUID, "E49A3003-F69A-11E8-8EB2-F2801F1B9FD1")
        XCTAssertEqual(config.commandCharacteristicUUID, "F0F1")
        XCTAssertEqual(config.deviceSerial, "129950")
        XCTAssertEqual(config.connectionTimeout, 10)
        XCTAssertEqual(config.sLinkTimeout, 5)
        XCTAssertEqual(config.keepAliveInterval, 3)
        XCTAssertEqual(config.rssiThreshold, -70)
        XCTAssertEqual(config.maxReconnectAttempts, 5)
        XCTAssertEqual(config.knownDeviceNames.count, 11)
    }

    func testFeatureFlagsValues() {
        let flags = FeatureFlags()
        
        XCTAssertTrue(flags.enableVAD)
        XCTAssertTrue(flags.enableLanguageDetection)
        XCTAssertTrue(flags.enableSwissGermanASR)
        XCTAssertTrue(flags.enableDiarization)
        XCTAssertTrue(flags.enableSummarization)
        XCTAssertTrue(flags.enableBLE)
        XCTAssertFalse(flags.enableDebugLogging)
    }
}
