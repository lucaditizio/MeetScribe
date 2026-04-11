import Foundation

@Observable
public final class SummaryPresenter: SummaryViewOutput, SummaryViewInput, SummaryInteractorOutput {
    public var state = SummaryState()
    private weak var view: SummaryViewInput?
    private let interactor: SummaryInteractorInput
    
    public init(view: SummaryViewInput?, interactor: SummaryInteractorInput) {
        self.view = view
        self.interactor = interactor
    }
    
    public func didTriggerViewReady() {
        state.isLoading = true
        interactor.obtainSummary()
    }
    
    public func displaySummary(topicSections: [SummaryTopicSection], actionItems: [String]) {
        state.topicSections = topicSections
        state.actionItems = actionItems
        state.isLoading = false
    }
    
    public func displayError(_ error: Error) {
        state.isLoading = false
    }
    
    public func didObtainSummary(topicSections: [SummaryTopicSection], actionItems: [String]) {
        state.topicSections = topicSections
        state.actionItems = actionItems
        state.isLoading = false
    }
    
    public func didFailWithError(_ error: Error) {
        state.isLoading = false
    }
}
