import Foundation

public protocol RecordingDetailRouterInput: AnyObject {
    func embedWaveformPlayback(with recording: Recording)
    func embedTranscript(with recording: Recording)
    func embedSummary(with recording: Recording)
    func embedMindMap(with recording: Recording)
    func didExitRecordingDetail()
    func openAgentGenerating(with recording: Recording)
}
