import Foundation

@Observable
public final class MindMapPresenter: MindMapViewOutput, MindMapViewInput, MindMapInteractorOutput {
    public var state = MindMapState()
    private weak var view: MindMapViewInput?
    private let interactor: MindMapInteractorInput
    
    public init(view: MindMapViewInput?, interactor: MindMapInteractorInput) {
        self.view = view
        self.interactor = interactor
    }
    
    public func didTriggerViewReady() {
        state.isLoading = true
        interactor.obtainMindMap()
    }
    
    public func displayMindMap(nodes: [MindMapNode]) {
        state.nodes = nodes
        state.isLoading = false
    }
    
    public func displayError(_ error: Error) {
        state.error = error
        state.isLoading = false
    }
    
    public func didObtainMindMap(nodes: [MindMapNode]) {
        displayMindMap(nodes: nodes)
    }
    
    public func didFailWithError(_ error: Error) {
        displayError(error)
    }
}
