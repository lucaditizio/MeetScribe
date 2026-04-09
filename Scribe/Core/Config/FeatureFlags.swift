import Foundation

/// Feature flags for enabling/disabling app features
struct FeatureFlags: Sendable {
    // MARK: - ML Pipeline Features
    let enableVAD = true
    let enableLanguageDetection = true
    let enableSwissGermanASR = true
    let enableDiarization = true
    let enableSummarization = true
    
    // MARK: - Hardware Features
    let enableBLE = true
    
    // MARK: - Debug Features
    let enableDebugLogging = false
}
