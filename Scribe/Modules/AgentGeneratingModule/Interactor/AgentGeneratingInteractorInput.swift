import Foundation
public protocol AgentGeneratingInteractorInput: AnyObject {
    func startProcessing(recordingId: String)
    func cancelProcessing()
}
