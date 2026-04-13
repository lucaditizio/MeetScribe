import Foundation
import OSLog

@Observable
class ProgressTracker {
    private let logger = Logger(subsystem: "com.scribe.app", category: "ML")
    
    var currentStage: String = ""
    var progress: Double = 0.0
    var currentStageIndex: Int = 0
    let totalStages: Int = 5
    
    private let stageNames: [String] = [
        "Voice Detection",
        "Language Detection",
        "Transcription",
        "Speaker Identification",
        "Generating Summary"
    ]
    
    var globalProgress: Double {
        let baseProgress = Double(currentStageIndex) / Double(totalStages)
        let stageContribution = progress / Double(totalStages)
        return baseProgress + stageContribution
    }
    
    init() {
        logger.info("ProgressTracker initialized with \(self.totalStages) stages")
    }
    
    func updateProgress(stage: String, progress: Double) {
        guard progress >= 0.0 && progress <= 1.0 else {
            logger.error("Invalid progress value: \(progress)")
            return
        }
        
        if let index = stageNames.firstIndex(of: stage) {
            currentStageIndex = index
            currentStage = stage
            self.progress = progress
            logger.info("Stage \(stage): \(progress * 100)% complete")
        } else {
            logger.error("Unknown stage: \(stage)")
        }
    }
    
    func getCurrentStageIndex() -> Int {
        return currentStageIndex
    }
    
    func getRemainingStages() -> Int {
        return totalStages - currentStageIndex - 1
    }
}
