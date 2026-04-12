import Foundation
import SwiftData

public final class RecordingListInteractor: RecordingListInteractorInput {
    private weak var output: RecordingListInteractorOutput?
    private let recordingRepository: RecordingRepositoryProtocol
    private let audioRecorder: AudioRecorderProtocol
    
    public init(
        output: RecordingListInteractorOutput?,
        recordingRepository: RecordingRepositoryProtocol,
        audioRecorder: AudioRecorderProtocol
    ) {
        self.output = output
        self.recordingRepository = recordingRepository
        self.audioRecorder = audioRecorder
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
                let recordings = try await recordingRepository.fetchAll()
                output?.didObtainRecordings(recordings)
            } catch {
                output?.didFailWithError(error)
            }
        }
    }
    
    public func startRecording() {
        Task {
            do {
                try await audioRecorder.startRecording(source: .rawInternal)
                output?.didStartRecording()
            } catch {
                output?.didFailWithError(error)
            }
        }
    }
    
    public func stopRecording() {
        Task {
            do {
                let result = try await audioRecorder.stopRecording()
                output?.didStopRecording(result: result)
            } catch {
                output?.didFailWithError(error)
            }
        }
    }
}
