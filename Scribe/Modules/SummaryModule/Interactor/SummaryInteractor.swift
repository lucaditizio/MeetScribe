import Foundation

public final class SummaryInteractor: SummaryInteractorInput {
    internal weak var output: SummaryInteractorOutput?
    private let recordingRepository: RecordingRepositoryProtocol
    private var recordingId: String?
    
    public init(
        output: SummaryInteractorOutput?,
        recordingRepository: RecordingRepositoryProtocol
    ) {
        self.output = output
        self.recordingRepository = recordingRepository
    }
    
    public func configureWith(recordingId: String) {
        self.recordingId = recordingId
    }
    
    public func obtainSummary() {
        guard let id = recordingId,
              let uuid = UUID(uuidString: id) else {
            output?.didFailWithError(SummaryError.noRecordingId)
            return
        }
        
        Task {
            do {
                guard let recording = try await recordingRepository.fetch(by: uuid) else {
                    output?.didFailWithError(SummaryError.recordingNotFound)
                    return
                }
                
                // Parse topic sections from meeting notes (simple parsing)
                let topicSections = Self.parseTopicSections(from: recording.meetingNotes ?? "")
                let actionItems = Self.parseActionItems(from: recording.actionItems ?? "")
                
                output?.didObtainSummary(topicSections: topicSections, actionItems: actionItems)
            } catch {
                output?.didFailWithError(error)
            }
        }
    }
    
    private static func parseTopicSections(from text: String) -> [SummaryTopicSection] {
        // Simple parsing - split by double newlines or headings
        let sections = text.components(separatedBy: "\n\n")
        return sections.compactMap { section in
            let lines = section.trimmingCharacters(in: .whitespacesAndNewlines).components(separatedBy: "\n")
            guard let title = lines.first, !title.isEmpty else { return nil }
            let content = lines.dropFirst().joined(separator: "\n")
            return SummaryTopicSection(title: title, content: content)
        }
    }
    
    private static func parseActionItems(from text: String) -> [String] {
        text.components(separatedBy: "\n").filter { !$0.isEmpty }
    }
}

public enum SummaryError: LocalizedError {
    case noRecordingId
    case recordingNotFound
    
    public var errorDescription: String? {
        switch self {
        case .noRecordingId: return "No recording ID configured"
        case .recordingNotFound: return "Recording not found"
        }
    }
}
