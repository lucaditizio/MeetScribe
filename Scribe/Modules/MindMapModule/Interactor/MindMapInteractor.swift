import Foundation
import SwiftData

public final class MindMapInteractor: MindMapInteractorInput {
    weak var output: MindMapInteractorOutput?
    private let recordingRepository: RecordingRepositoryProtocol
    private var recordingId: String?
    
    public init(
        output: MindMapInteractorOutput?,
        recordingRepository: RecordingRepositoryProtocol
    ) {
        self.output = output
        self.recordingRepository = recordingRepository
    }
    
    public func configureWith(recordingId: String) {
        self.recordingId = recordingId
    }
    
    public func obtainMindMap() {
        guard let id = recordingId,
              let uuid = UUID(uuidString: id) else {
            output?.didFailWithError(MindMapError.noRecordingId)
            return
        }
        
        Task {
            do {
                guard let recording = try await recordingRepository.fetch(by: uuid) else {
                    output?.didFailWithError(MindMapError.recordingNotFound)
                    return
                }
                
                // Parse mind map JSON from meetingNotes or other field
                let nodes = Self.parseMindMap(from: recording.meetingNotes ?? "", summaryId: recording.id)
                output?.didObtainMindMap(nodes: nodes)
            } catch {
                output?.didFailWithError(error)
            }
        }
    }
    
    private static func parseMindMap(from jsonString: String, summaryId: UUID) -> [MindMapNode] {
        guard let data = jsonString.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let nodesArray = json["nodes"] as? [[String: Any]] else {
            // Return default root node if no valid JSON
            return [MindMapNode(id: UUID(), summaryId: summaryId, text: "Meeting Overview", order: 0, level: 0)]
        }
        
        return nodesArray.compactMap { dict -> MindMapNode? in
            guard let text = dict["text"] as? String else { return nil }
            let order = dict["order"] as? Int ?? 0
            let level = dict["level"] as? Int ?? 0
            let parentId = dict["parentId"] as? UUID
            let children = (dict["children"] as? [[String: Any]])?.compactMap { childDict -> MindMapNode? in
                guard let childText = childDict["text"] as? String else { return nil }
                let childOrder = childDict["order"] as? Int ?? 0
                let childLevel = childDict["level"] as? Int ?? 0
                let childParentId = childDict["parentId"] as? UUID
                return MindMapNode(id: UUID(), summaryId: summaryId, parentId: childParentId, text: childText, order: childOrder, level: childLevel)
            } ?? []
            return MindMapNode(id: UUID(), summaryId: summaryId, parentId: parentId, text: text, order: order, level: level)
        }
    }
}

public enum MindMapError: LocalizedError {
    case noRecordingId
    case recordingNotFound
    
    public var errorDescription: String? {
        switch self {
        case .noRecordingId: return "No recording ID configured"
        case .recordingNotFound: return "Recording not found"
        }
    }
}
