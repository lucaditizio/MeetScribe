import Foundation
import SwiftData
import Combine

public final class RecordingListInteractor: RecordingListInteractorInput {
    private weak var output: RecordingListInteractorOutput?
    private let recordingRepository: RecordingRepositoryProtocol
    private let audioRecorder: AudioRecorderProtocol
    private let deviceConnectionManager: DeviceConnectionManagerProtocol
    
    public init(
        output: RecordingListInteractorOutput?,
        recordingRepository: RecordingRepositoryProtocol,
        audioRecorder: AudioRecorderProtocol,
        deviceConnectionManager: DeviceConnectionManagerProtocol
    ) {
        self.output = output
        self.recordingRepository = recordingRepository
        self.audioRecorder = audioRecorder
        self.deviceConnectionManager = deviceConnectionManager
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
        let source: RecordingSource = deviceConnectionManager.isConnected ? .rawBle : .rawInternal
        Task {
            do {
                try await audioRecorder.startRecording(source: source)
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
