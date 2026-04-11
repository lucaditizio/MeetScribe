import Foundation
public protocol AgentGeneratingViewInput: AnyObject {
    func displayProgress(stage: String, progress: Double)
    func displayCompletion()
    func displayError(_ error: Error)
}
