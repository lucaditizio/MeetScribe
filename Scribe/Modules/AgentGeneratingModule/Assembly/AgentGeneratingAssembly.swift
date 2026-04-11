import Foundation
import Combine

public final class AgentGeneratingAssembly {
    public static func createModule(recordingId: String, moduleOutput: AgentGeneratingModuleOutput?) -> AgentGeneratingViewInput {
        let interactor = AgentGeneratingInteractor(output: nil, moduleOutput: moduleOutput, inferencePipeline: MockPipeline())
        let presenter = AgentGeneratingPresenter(view: nil, interactor: interactor)
        return presenter
    }
}

private final class MockPipeline: InferencePipelineProtocol {
    var progressPublisher: AnyPublisher<InferenceProgress, Never> { Just(InferenceProgress(stage: "Initializing", progress: 0)).eraseToAnyPublisher() }
    
    func process(recording: Recording) async throws -> (Transcript, MeetingSummary) {
        let transcript = Transcript(id: UUID(), recordingId: UUID(), fullText: "", detectedLanguage: nil, createdAt: Date())
        let summary = MeetingSummary(id: UUID(), recordingId: UUID(), overview: "", keyPoints: [], actionItems: [], createdAt: Date())
        return (transcript, summary)
    }
    
    func cancel() {}
}
