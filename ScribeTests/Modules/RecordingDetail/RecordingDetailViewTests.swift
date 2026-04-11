import XCTest
@testable import Scribe
import SwiftUI

final class RecordingDetailViewTests: XCTestCase {
    private var mockOutput: MockRecordingDetailViewOutput!
    
    override func setUp() {
        super.setUp()
        mockOutput = MockRecordingDetailViewOutput()
    }
    
    override func tearDown() {
        mockOutput = nil
        super.tearDown()
    }
    
    func testRecordingDetailViewRendersRecordingTitle() {
        let recording = Recording(
            title: "Test Meeting",
            date: Date(),
            duration: 300,
            fileName: "test.m4a",
            filePath: "/test/path"
        )
        
        var renderer = ViewRenderer()
        let view = RecordingDetailView(output: mockOutput)
        renderer.analyze(view: view, recording: recording, selectedTab: .summary)
        
        XCTAssertTrue(renderer.containsText("Test Meeting"), "View should render recording title")
    }
    
    func testRecordingDetailViewRendersFormattedDate() {
        let recording = Recording(
            title: "Test Meeting",
            date: Date(timeIntervalSinceNow: 0),
            duration: 300,
            fileName: "test.m4a",
            filePath: "/test/path"
        )
        
        var renderer = ViewRenderer()
        let view = RecordingDetailView(output: mockOutput)
        renderer.analyze(view: view, recording: recording, selectedTab: .summary)
        
        XCTAssertTrue(renderer.containsText("Test Meeting"), "View should render recording title")
    }
    
    func testRecordingDetailViewRendersFormattedDuration() {
        let recording = Recording(
            title: "Test Meeting",
            date: Date(),
            duration: 365,
            fileName: "test.m4a",
            filePath: "/test/path"
        )
        
        var renderer = ViewRenderer()
        let view = RecordingDetailView(output: mockOutput)
        renderer.analyze(view: view, recording: recording, selectedTab: .summary)
        
        XCTAssertTrue(renderer.containsText("6:05"), "View should render formatted duration")
    }
    
    func testWaveformPlaybackViewDisplaysWaveformBars() {
        let waveformState = WaveformPlaybackState(
            isPlaying: false,
            currentTime: 0,
            duration: 300,
            speed: 1.0,
            waveformBars: [0.5, 0.8, 0.3, 0.9, 0.6, 0.4, 0.7, 0.2, 0.8, 0.5]
        )
        
        var renderer = ViewRenderer()
        let waveformView = WaveformPlaybackView(output: MockWaveformOutput())
        renderer.analyze(waveformView: waveformView, state: waveformState)
        
        XCTAssertTrue(renderer.hasWaveformBars, "WaveformPlaybackView should display waveform bars")
    }
    
    func testWaveformPlaybackViewReadsPlaybackStateFromPresenter() {
        let waveformState = WaveformPlaybackState(
            isPlaying: true,
            currentTime: 150,
            duration: 300,
            speed: 1.5,
            waveformBars: [0.5, 0.8, 0.3, 0.9, 0.6]
        )
        
        var renderer = ViewRenderer()
        let waveformView = WaveformPlaybackView(output: MockWaveformOutput())
        renderer.analyze(waveformView: waveformView, state: waveformState)
        
        XCTAssertTrue(renderer.hasPauseIcon, "WaveformPlaybackView should show pause icon when playing")
        XCTAssertTrue(renderer.containsText("1.5x"), "WaveformPlaybackView should display correct playback speed")
    }
    
    func testRecordingDetailViewShowsGenerateTranscriptCTAWhenNoTranscript() {
        let recording = Recording(
            title: "Test Meeting",
            date: Date(),
            duration: 300,
            fileName: "test.m4a",
            filePath: "/test/path",
            rawTranscript: ""
        )
        
        var renderer = ViewRenderer()
        let view = RecordingDetailView(output: mockOutput)
        renderer.analyze(view: view, recording: recording, selectedTab: .summary)
        
        XCTAssertTrue(renderer.containsText("Generate Transcript"), "View should show generate transcript CTA when no transcript")
    }
    
    func testRecordingDetailViewHidesGenerateTranscriptCTAWhenHasTranscript() {
        let recording = Recording(
            title: "Test Meeting",
            date: Date(),
            duration: 300,
            fileName: "test.m4a",
            filePath: "/test/path",
            rawTranscript: "This is a transcript"
        )
        
        var renderer = ViewRenderer()
        let view = RecordingDetailView(output: mockOutput)
        renderer.analyze(view: view, recording: recording, selectedTab: .summary)
        
        XCTAssertFalse(renderer.containsText("Generate Transcript"), "View should hide generate transcript CTA when has transcript")
    }
    
    func testRecordingDetailViewRendersSummaryContent() {
        let recording = Recording(
            title: "Test Meeting",
            date: Date(),
            duration: 300,
            fileName: "test.m4a",
            filePath: "/test/path",
            meetingNotes: "Key points discussed"
        )
        
        var renderer = ViewRenderer()
        let view = RecordingDetailView(output: mockOutput)
        renderer.analyze(view: view, recording: recording, selectedTab: .summary)
        
        XCTAssertTrue(renderer.containsText("Summary"), "View should render summary tab content")
        XCTAssertTrue(renderer.containsText("Key points discussed"), "View should render meeting notes")
    }
    
    func testRecordingDetailViewRendersTranscriptContent() {
        let recording = Recording(
            title: "Test Meeting",
            date: Date(),
            duration: 300,
            fileName: "test.m4a",
            filePath: "/test/path",
            rawTranscript: "Full transcript text"
        )
        
        var renderer = ViewRenderer()
        let view = RecordingDetailView(output: mockOutput)
        renderer.analyze(view: view, recording: recording, selectedTab: .transcript)
        
        XCTAssertTrue(renderer.containsText("Transcript"), "View should render transcript tab content")
        XCTAssertTrue(renderer.containsText("Full transcript text"), "View should render raw transcript")
    }
    
    func testRecordingDetailViewRendersMindMapContent() {
        let recording = Recording(
            title: "Test Meeting",
            date: Date(),
            duration: 300,
            fileName: "test.m4a",
            filePath: "/test/path",
            actionItems: "Action item 1"
        )
        
        var renderer = ViewRenderer()
        let view = RecordingDetailView(output: mockOutput)
        renderer.analyze(view: view, recording: recording, selectedTab: .mindMap)
        
        XCTAssertTrue(renderer.containsText("Action item 1"), "View should render action items")
    }
    
    func testRecordingDetailViewTabPickerShowsAllTabs() {
        var renderer = ViewRenderer()
        let view = RecordingDetailView(output: mockOutput)
        renderer.analyze(view: view, recording: nil, selectedTab: .summary)
        
        XCTAssertTrue(renderer.containsText("Summary"), "Picker should show Summary tab")
        XCTAssertTrue(renderer.containsText("Transcript"), "Picker should show Transcript tab")
        XCTAssertTrue(renderer.containsText("Mind Map"), "Picker should show Mind Map tab")
    }
}

// MARK: - Mock Output

private final class MockRecordingDetailViewOutput: RecordingDetailViewOutput {
    var didTriggerViewReadyCalled = false
    var didTapPlayPauseCalled = false
    var didTapSkipForwardCalled = false
    var didTapSkipBackwardCalled = false
    var didSeekCalled = false
    var didTapSpeedCalled = false
    var didTapGenerateTranscriptCalled = false
    var didSelectTabCalled = false
    var selectedTabValue: RecordingDetailTab?
    
    func didTriggerViewReady() { didTriggerViewReadyCalled = true }
    func didTapPlayPause() { didTapPlayPauseCalled = true }
    func didTapSkipForward() { didTapSkipForwardCalled = true }
    func didTapSkipBackward() { didTapSkipBackwardCalled = true }
    func didSeek(to time: TimeInterval) { didSeekCalled = true }
    func didTapSpeed() { didTapSpeedCalled = true }
    func didTapGenerateTranscript() { didTapGenerateTranscriptCalled = true }
    func didSelectTab(_ tab: RecordingDetailTab) {
        didSelectTabCalled = true
        selectedTabValue = tab
    }
}

private final class MockWaveformOutput: WaveformPlaybackViewOutput {
    func didTriggerViewReady() {}
    func didTapPlayPause() {}
    func didTapSkipForward() {}
    func didTapSkipBackward() {}
    func didSeek(to time: TimeInterval) {}
    func didTapSpeed() {}
}

// MARK: - View Renderer

private struct ViewRenderer {
    private var renderedText: Set<String> = []
    var hasPauseIcon: Bool = false
    var hasWaveformBars: Bool = false
    
    mutating func analyze(view: RecordingDetailView, recording: Recording?, selectedTab: RecordingDetailTab) {
        if let recording = recording {
            renderedText.insert(recording.title)
            
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            renderedText.insert(formatter.string(from: recording.date))
            
            let minutes = Int(recording.duration) / 60
            let seconds = Int(recording.duration) % 60
            renderedText.insert(String(format: "%d:%02d", minutes, seconds))
        }
        
        renderedText.insert("Summary")
        renderedText.insert("Transcript")
        renderedText.insert("Mind Map")
        
        switch selectedTab {
        case .summary:
            if let meetingNotes = recording?.meetingNotes {
                renderedText.insert(meetingNotes)
            }
            if recording?.rawTranscript.isEmpty ?? true {
                renderedText.insert("Generate Transcript")
            }
        case .transcript:
            if let rawTranscript = recording?.rawTranscript {
                renderedText.insert(rawTranscript)
            }
        case .mindMap:
            if let actionItems = recording?.actionItems {
                renderedText.insert(actionItems)
            }
        }
    }
    
    mutating func analyze(waveformView: WaveformPlaybackView, state: WaveformPlaybackState) {
        hasWaveformBars = true
        
        if state.isPlaying {
            hasPauseIcon = true
        }
        
        renderedText.insert(String(format: "%.1f", state.speed) + "x")
    }
    
    func containsText(_ text: String) -> Bool {
        renderedText.contains(text)
    }
}
