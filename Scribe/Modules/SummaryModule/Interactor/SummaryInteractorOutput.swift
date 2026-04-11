import Foundation

public protocol SummaryInteractorOutput: AnyObject {
    func didObtainSummary(topicSections: [SummaryTopicSection], actionItems: [String])
    func didFailWithError(_ error: Error)
}
