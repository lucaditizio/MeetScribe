import Foundation

/// Assembly for AgentGeneratingModule.
/// Accepts the real InferencePipelineProtocol injected from AppAssembly/ServiceRegistry,
/// replacing the MockPipeline placeholder.
public final class AgentGeneratingAssembly {

    public static func createModule(
        recordingId: String,
        inferencePipeline: InferencePipelineProtocol,
        moduleOutput: AgentGeneratingModuleOutput?,
        recordingRepository: RecordingRepositoryProtocol
    ) -> AgentGeneratingPresenter {
        let interactor = AgentGeneratingInteractor(
            output: nil,
            moduleOutput: moduleOutput,
            inferencePipeline: inferencePipeline,
            recordingRepository: recordingRepository
        )
        let presenter = AgentGeneratingPresenter(view: nil, interactor: interactor)
        interactor.output = presenter
        interactor.configureWith(recordingId: recordingId, moduleOutput: moduleOutput)
        return presenter
    }
}
