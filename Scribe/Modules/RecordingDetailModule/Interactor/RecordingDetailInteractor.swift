import Foundation

public final class RecordingDetailInteractor: RecordingDetailInteractorInput {
    weak var output: RecordingDetailInteractorOutput?
    private let recordingRepository: RecordingRepositoryProtocol
    
    public init(
        output: RecordingDetailInteractorOutput?,
        recordingRepository: RecordingRepositoryProtocol
    ) {
        self.output = output
        self.recordingRepository = recordingRepository
    }
    
    public func obtainRecording(id: String) {
        Task {
            do {
                guard let recordingId = UUID(uuidString: id) else {
                    output?.didFailWithError(RecordingDetailError.invalidId)
                    return
                }
                guard let recording = try await recordingRepository.fetch(by: recordingId) else {
                    output?.didFailWithError(RecordingDetailError.notFound)
                    return
                }
                output?.didObtainRecording(recording)
            } catch {
                output?.didFailWithError(error)
            }
        }
    }
    
    public func updateRecording(_ recording: Recording) {
        Task {
            do {
                try await recordingRepository.update(recording)
                output?.didObtainRecording(recording)
            } catch {
                output?.didFailWithError(error)
            }
        }
    }
}

public enum RecordingDetailError: LocalizedError {
    case notFound
    case invalidId
    
    public var errorDescription: String? {
        switch self {
        case .notFound:
            return "Recording not found"
        case .invalidId:
            return "Invalid recording ID"
        }
    }
}
