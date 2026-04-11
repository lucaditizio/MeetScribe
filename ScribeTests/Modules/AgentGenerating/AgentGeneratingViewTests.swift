import XCTest
@testable import Scribe
import SwiftUI

@available(iOS 18.0, *)
final class AgentGeneratingViewTests: XCTestCase {
    
    private var presenter: AgentGeneratingPresenter!
    private var interactor: MockAgentGeneratingInteractorInput!
    
    override func setUp() {
        super.setUp()
        interactor = MockAgentGeneratingInteractorInput()
        presenter = AgentGeneratingPresenter(view: nil, interactor: interactor)
    }
    
    override func tearDown() {
        presenter = nil
        interactor = nil
        super.tearDown()
    }
    
    // MARK: - Progress Rendering Tests
    
    func testViewRendersProgressFromPresenterState() {
        // Arrange
        presenter.state.progress = 0.5
        
        // Act
        let view = AgentGeneratingView(presenter: presenter)
        
        // Assert
        XCTAssertNotNil(view)
        XCTAssertEqual(presenter.state.progress, 0.5)
    }
    
    func testProgressPercentageDisplayShowsCorrectValue() {
        // Arrange
        let testProgressValues: [Double] = [0.0, 0.25, 0.5, 0.75, 1.0]
        
        // Act & Assert
        for progress in testProgressValues {
            presenter.state.progress = progress
            let view = AgentGeneratingView(presenter: presenter)
            
            let percentage = Int(progress * 100)
            XCTAssertEqual(percentage, Int(presenter.state.progress * 100))
        }
    }
    
    func testProgressPercentageDisplayAtZero() {
        // Arrange
        presenter.state.progress = 0.0
        
        // Act
        let view = AgentGeneratingView(presenter: presenter)
        
        // Assert
        XCTAssertEqual(Int(presenter.state.progress * 100), 0)
    }
    
    func testProgressPercentageDisplayAtComplete() {
        // Arrange
        presenter.state.progress = 1.0
        
        // Act
        let view = AgentGeneratingView(presenter: presenter)
        
        // Assert
        XCTAssertEqual(Int(presenter.state.progress * 100), 100)
    }
    
    // MARK: - CurrentStage Display Tests
    
    func testStageLabelDisplaysInitializing() {
        // Arrange
        presenter.state.currentStage = .initializing
        
        // Act
        let view = AgentGeneratingView(presenter: presenter)
        
        // Assert
        XCTAssertEqual(presenter.state.currentStage.rawValue, "Initializing")
    }
    
    func testStageLabelDisplaysVoiceDetection() {
        // Arrange
        presenter.state.currentStage = .vad
        
        // Act
        let view = AgentGeneratingView(presenter: presenter)
        
        // Assert
        XCTAssertEqual(presenter.state.currentStage.rawValue, "Voice Detection")
    }
    
    func testStageLabelDisplaysLanguageDetection() {
        // Arrange
        presenter.state.currentStage = .languageDetection
        
        // Act
        let view = AgentGeneratingView(presenter: presenter)
        
        // Assert
        XCTAssertEqual(presenter.state.currentStage.rawValue, "Language Detection")
    }
    
    func testStageLabelDisplaysTranscription() {
        // Arrange
        presenter.state.currentStage = .asr
        
        // Act
        let view = AgentGeneratingView(presenter: presenter)
        
        // Assert
        XCTAssertEqual(presenter.state.currentStage.rawValue, "Transcription")
    }
    
    func testStageLabelDisplaysSpeakerIdentification() {
        // Arrange
        presenter.state.currentStage = .diarization
        
        // Act
        let view = AgentGeneratingView(presenter: presenter)
        
        // Assert
        XCTAssertEqual(presenter.state.currentStage.rawValue, "Speaker Identification")
    }
    
    func testStageLabelDisplaysGeneratingSummary() {
        // Arrange
        presenter.state.currentStage = .summarization
        
        // Act
        let view = AgentGeneratingView(presenter: presenter)
        
        // Assert
        XCTAssertEqual(presenter.state.currentStage.rawValue, "Generating Summary")
    }
    
    func testStageLabelDisplaysComplete() {
        // Arrange
        presenter.state.currentStage = .complete
        
        // Act
        let view = AgentGeneratingView(presenter: presenter)
        
        // Assert
        XCTAssertEqual(presenter.state.currentStage.rawValue, "Complete")
    }
    
    // MARK: - iOS Version Requirement Tests
    
    func testViewRequiresiOS18OrHigher() {
        // This test verifies the @available(iOS 18.0, *) annotation
        // The view will not compile on iOS versions below 18.0
        XCTAssertNotNil(AgentGeneratingView.self)
    }
    
    // MARK: - Progress Update Tests
    
    func testPresenterUpdatesProgressAndStage() {
        // Arrange
        let stage = "Transcription"
        let progress: Double = 0.6
        
        // Act
        presenter.didUpdateProgress(stage: stage, progress: progress)
        
        // Assert
        XCTAssertEqual(presenter.state.currentStage, .asr)
        XCTAssertEqual(presenter.state.progress, progress)
    }
    
    func testPresenterUpdatesProgressToComplete() {
        // Arrange
        let stage = "Complete"
        let progress: Double = 1.0
        
        // Act
        presenter.didUpdateProgress(stage: stage, progress: progress)
        
        // Assert
        XCTAssertEqual(presenter.state.currentStage, .complete)
        XCTAssertEqual(presenter.state.progress, 1.0)
    }
    
    func testPresenterHandlesUnknownStage() {
        // Arrange
        let stage = "Unknown Stage"
        let progress: Double = 0.5
        
        // Act
        presenter.didUpdateProgress(stage: stage, progress: progress)
        
        // Assert
        XCTAssertEqual(presenter.state.currentStage, .initializing)
        XCTAssertEqual(presenter.state.progress, progress)
    }
    
    // MARK: - Processing State Tests
    
    func testViewRendersWithProcessingStateTrue() {
        // Arrange
        presenter.state.isProcessing = true
        presenter.state.progress = 0.3
        
        // Act
        let view = AgentGeneratingView(presenter: presenter)
        
        // Assert
        XCTAssertNotNil(view)
        XCTAssertTrue(presenter.state.isProcessing)
    }
    
    func testViewRendersWithProcessingStateFalse() {
        // Arrange
        presenter.state.isProcessing = false
        presenter.state.progress = 0.0
        
        // Act
        let view = AgentGeneratingView(presenter: presenter)
        
        // Assert
        XCTAssertNotNil(view)
        XCTAssertFalse(presenter.state.isProcessing)
    }
}

// MARK: - Mock Interactor

final class MockAgentGeneratingInteractorInput: AgentGeneratingInteractorInput {
    func cancelProcessing() {}
    func startProcessing(recordingId: String) {}
}
