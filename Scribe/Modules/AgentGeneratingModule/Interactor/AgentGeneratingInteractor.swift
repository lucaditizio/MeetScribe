import Foundation

public final class AgentGeneratingInteractor: AgentGeneratingInteractorInput {
    private weak var output: AgentGeneratingInteractorOutput?
    private weak var moduleOutput: AgentGeneratingModuleOutput?
    private let inferencePipeline: InferencePipelineProtocol
    private var recordingId: String?
    private var currentTask: Task<Void, Never>?
    
    public init(
        output: AgentGeneratingInteractorOutput?,
        moduleOutput: AgentGeneratingModuleOutput?,
        inferencePipeline: InferencePipelineProtocol
    ) {
        self.output = output
        self.moduleOutput = moduleOutput
        self.inferencePipeline = inferencePipeline
    }
    
    public func configureWith(recordingId: String, moduleOutput: AgentGeneratingModuleOutput?) {
        self.recordingId = recordingId
        self.moduleOutput = moduleOutput
    }
    
    public func startProcessing(recordingId: String) {
        self.recordingId = recordingId
        
        currentTask = Task {
            do {
                output?.didUpdateProgress(stage: ProcessingStage.vad.rawValue, progress: 0.1)
                try await Task.sleep(nanoseconds: 500_000_000)
                
                output?.didUpdateProgress(stage: ProcessingStage.languageDetection.rawValue, progress: 0.3)
                try await Task.sleep(nanoseconds: 500_000_000)
                
                output?.didUpdateProgress(stage: ProcessingStage.asr.rawValue, progress: 0.5)
                try await Task.sleep(nanoseconds: 500_000_000)
                
                output?.didUpdateProgress(stage: ProcessingStage.diarization.rawValue, progress: 0.8)
                try await Task.sleep(nanoseconds: 500_000_000)
                
                output?.didUpdateProgress(stage: ProcessingStage.summarization.rawValue, progress: 0.95)
                try await Task.sleep(nanoseconds: 500_000_000)
                
                output?.didUpdateProgress(stage: ProcessingStage.complete.rawValue, progress: 1.0)
                output?.didCompleteProcessing()
                moduleOutput?.didFinishProcessing()
                
            } catch is CancellationError {
            } catch {
                output?.didFailWithError(error)
                moduleOutput?.didFailWithError(error)
            }
        }
    }
    
    public func cancelProcessing() {
        currentTask?.cancel()
        currentTask = nil
    }
}
