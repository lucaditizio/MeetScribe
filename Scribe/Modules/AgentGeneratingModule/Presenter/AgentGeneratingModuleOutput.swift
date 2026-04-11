import Foundation
public protocol AgentGeneratingModuleOutput: AnyObject {
    func didFinishProcessing()
    func didFailWithError(_ error: Error)
}
