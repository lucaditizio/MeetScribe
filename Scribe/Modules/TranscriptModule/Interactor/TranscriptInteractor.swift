import Foundation

public final class TranscriptInteractor: TranscriptInteractorInput {
    private weak var output: TranscriptInteractorOutput?
    private let recordingRepository: RecordingRepositoryProtocol
    private var recordingId: String?
    
    public init(
        output: TranscriptInteractorOutput?,
        recordingRepository: RecordingRepositoryProtocol
    ) {
        self.output = output
        self.recordingRepository = recordingRepository
    }
    
    public func configureWith(recordingId: String) {
        self.recordingId = recordingId
    }
    
    public func obtainTranscriptSegments() {
        guard let id = recordingId,
              let uuid = UUID(uuidString: id) else {
            output?.didFailWithError(TranscriptError.noRecordingId)
            return
        }
        
        Task {
            do {
                guard let recording = try await recordingRepository.fetch(by: uuid) else {
                    output?.didFailWithError(TranscriptError.recordingNotFound)
                    return
                }
                
                let segments = recording.transcript?.segments ?? []
                output?.didObtainTranscriptSegments(segments)
            } catch {
                output?.didFailWithError(error)
            }
        }
    }
    
    public func renameSpeaker(from oldName: String, to newName: String) {
        guard let id = recordingId,
              let uuid = UUID(uuidString: id) else {
            output?.didFailWithError(TranscriptError.noRecordingId)
            return
        }
        
        Task {
            do {
                guard let recording = try await recordingRepository.fetch(by: uuid) else {
                    output?.didFailWithError(TranscriptError.recordingNotFound)
                    return
                }
                
                let updatedRawTranscript = recording.rawTranscript.replacingOccurrences(of: oldName, with: newName)
                
                var updatedActionItems = recording.actionItems
                if let items = recording.actionItems {
                    updatedActionItems = items.replacingOccurrences(of: oldName, with: newName)
                }
                
                var updatedMeetingNotes = recording.meetingNotes
                if let notes = recording.meetingNotes {
                    updatedMeetingNotes = notes.replacingOccurrences(of: oldName, with: newName)
                }
                
                recording.rawTranscript = updatedRawTranscript
                recording.actionItems = updatedActionItems
                recording.meetingNotes = updatedMeetingNotes
                
                try await recordingRepository.update(recording)
                
                obtainTranscriptSegments()
            } catch {
                output?.didFailWithError(error)
            }
        }
    }
}

public enum TranscriptError: LocalizedError {
    case noRecordingId
    case recordingNotFound
    
    public var errorDescription: String? {
        switch self {
        case .noRecordingId:
            return "No recording ID configured"
        case .recordingNotFound:
            return "Recording not found"
        }
    }
}
