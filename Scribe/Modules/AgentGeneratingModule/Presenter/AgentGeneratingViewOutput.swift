import Foundation
public protocol AgentGeneratingViewOutput: AnyObject {
    func didTriggerViewReady()
    func didTapCancel()
}
