import Foundation

public protocol SummaryViewInput: AnyObject {
    func displaySummary(topicSections: [SummaryTopicSection], actionItems: [String])
    func displayError(_ error: Error)
}
