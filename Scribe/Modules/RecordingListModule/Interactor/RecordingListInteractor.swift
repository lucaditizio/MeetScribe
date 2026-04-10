import Foundation

public final class RecordingListInteractor: RecordingListInteractorInput {
    private weak var output: RecordingListInteractorOutput?
    private let recordingRepository: RecordingRepositoryProtocol
    
    public init(
        output: RecordingListInteractorOutput?,
        recordingRepository: RecordingRepositoryProtocol
    ) {
        self.output = output
        self.recordingRepository = recordingRepository
    }
    
    public func obtainRecordings() {
        Task {
            do {
                let recordings = try await recordingRepository.fetchAll()
                output?.didObtainRecordings(recordings)
            } catch {
                output?.didFailWithError(error)
            }
        }
    }
    
    public func deleteRecording(id: String) {
        Task {
            do {
                guard let uuid = UUID(uuidString: id),
                      let recording = try await recordingRepository.fetch(by: uuid) else {
                    return
                }
                try await recordingRepository.delete(recording)
                // Refresh after delete
                let recordings = try await recordingRepository.fetchAll()
                output?.didObtainRecordings(recordings)
            } catch {
                output?.didFailWithError(error)
            }
        }
    }
}
