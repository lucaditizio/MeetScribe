import Foundation
import Combine

public final class AgentGeneratingInteractor: AgentGeneratingInteractorInput {
    weak var output: AgentGeneratingInteractorOutput?
    weak var moduleOutput: AgentGeneratingModuleOutput?
    private let inferencePipeline: InferencePipelineProtocol
    private let recordingRepository: RecordingRepositoryProtocol
    private var recordingId: String?
    private var currentTask: Task<Void, Never>?
    private var progressCancellable: AnyCancellable?
    
    public init(
        output: AgentGeneratingInteractorOutput?,
        moduleOutput: AgentGeneratingModuleOutput?,
        inferencePipeline: InferencePipelineProtocol,
        recordingRepository: RecordingRepositoryProtocol
    ) {
        self.output = output
        self.moduleOutput = moduleOutput
        self.inferencePipeline = inferencePipeline
        self.recordingRepository = recordingRepository
    }
    
    public func configureWith(recordingId: String, moduleOutput: AgentGeneratingModuleOutput?) {
        self.recordingId = recordingId
        self.moduleOutput = moduleOutput
    }
    
    public func startProcessing(recordingId: String? = nil) {
        progressCancellable = inferencePipeline.progressPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] inferenceProgress in
                self?.output?.didUpdateProgress(stage: inferenceProgress.stage, progress: inferenceProgress.progress)
            }
        
        currentTask = Task { [weak self] in
            guard let self = self else { return }
            guard let rid = self.recordingId else {
                let error = NSError(domain: "AgentGeneratingInteractor", code: 2, userInfo: [NSLocalizedDescriptionKey: "Recording ID not configured"])
                self.output?.didFailWithError(error)
                self.moduleOutput?.didFailWithError(error)
                return
            }
            do {
                let id = UUID(uuidString: rid)
                guard let recording = try await self.recordingRepository.fetch(by: id ?? UUID()) else {
                    let error = NSError(domain: "AgentGeneratingInteractor", code: 1, userInfo: [NSLocalizedDescriptionKey: "Recording not found"])
                    self.output?.didFailWithError(error)
                    self.moduleOutput?.didFailWithError(error)
                    return
                }
                
                let result = try await self.inferencePipeline.process(recording: recording)
                
                self.output?.didUpdateProgress(stage: ProcessingStage.complete.rawValue, progress: 1.0)
                self.output?.didCompleteProcessing()
                self.moduleOutput?.didFinishProcessing()
                
            } catch is CancellationError {
            } catch {
                self.output?.didFailWithError(error)
                self.moduleOutput?.didFailWithError(error)
            }
        }
    }
    
    public func cancelProcessing() {
        currentTask?.cancel()
        currentTask = nil
    }
}
