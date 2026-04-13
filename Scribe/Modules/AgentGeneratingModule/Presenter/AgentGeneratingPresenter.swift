import Foundation

@Observable
public final class AgentGeneratingPresenter: AgentGeneratingViewOutput, AgentGeneratingInteractorOutput, AgentGeneratingViewInput {
    public var state = AgentGeneratingState()
    private weak var view: AgentGeneratingViewInput?
    private let interactor: AgentGeneratingInteractorInput
    
    public init(view: AgentGeneratingViewInput?, interactor: AgentGeneratingInteractorInput) {
        self.view = view
        self.interactor = interactor
    }
    
    public func didTriggerViewReady() {
        interactor.startProcessing(recordingId: nil)
    }
    
    public func didTapCancel() {
        interactor.cancelProcessing()
    }
    
    public func didUpdateProgress(stage: String, progress: Double) {
        state.currentStage = ProcessingStage(rawValue: stage) ?? .initializing
        state.progress = progress
        view?.displayProgress(stage: stage, progress: progress)
    }
    
    public func didCompleteProcessing() {
        state.isProcessing = false
        state.progress = 1.0
        view?.displayCompletion()
    }
    
    public func didFailWithError(_ error: Error) {
        state.isProcessing = false
        state.error = error
        view?.displayError(error)
    }
    
    public func displayProgress(stage: String, progress: Double) {}
    public func displayCompletion() {}
    public func displayError(_ error: Error) {}
}
