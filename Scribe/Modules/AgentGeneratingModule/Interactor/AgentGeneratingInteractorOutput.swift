import Foundation
public protocol AgentGeneratingInteractorOutput: AnyObject {
    func didUpdateProgress(stage: String, progress: Double)
    func didCompleteProcessing()
    func didFailWithError(_ error: Error)
}
