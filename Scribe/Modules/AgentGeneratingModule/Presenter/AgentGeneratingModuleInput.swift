import Foundation
public protocol AgentGeneratingModuleInput: AnyObject {
    func configureWith(recordingId: String)
}
