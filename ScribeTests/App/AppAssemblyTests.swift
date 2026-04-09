import XCTest
import SwiftUI
@testable import Scribe

final class AppAssemblyTests: XCTestCase {
    func testAppAssemblySingletonExists() {
        let assembly = AppAssembly.shared
        XCTAssertNotNil(assembly)
    }
    
    func testAllModuleFactoriesReturnViews() {
        let assembly = AppAssembly.shared
        
        let recordingList = assembly.makeRecordingListModule(output: nil)
        XCTAssertNotNil(recordingList)
        
        let recordingDetail = assembly.makeRecordingDetailModule(recordingId: UUID(), output: nil)
        XCTAssertNotNil(recordingDetail)
        
        let waveformPlayback = assembly.makeWaveformPlaybackModule(recordingId: UUID(), output: nil)
        XCTAssertNotNil(waveformPlayback)
        
        let transcript = assembly.makeTranscriptModule(recordingId: UUID(), output: nil)
        XCTAssertNotNil(transcript)
        
        let summary = assembly.makeSummaryModule(recordingId: UUID(), output: nil)
        XCTAssertNotNil(summary)
        
        let mindMap = assembly.makeMindMapModule(recordingId: UUID(), output: nil)
        XCTAssertNotNil(mindMap)
        
        let agentGenerating = assembly.makeAgentGeneratingModule(recordingId: UUID(), output: nil)
        XCTAssertNotNil(agentGenerating)
        
        let deviceSettings = assembly.makeDeviceSettingsModule(output: nil)
        XCTAssertNotNil(deviceSettings)
    }
}
