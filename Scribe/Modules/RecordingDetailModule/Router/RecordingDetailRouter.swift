import Foundation
import SwiftUI
import Combine

@Observable
public final class RecordingDetailRouter: RecordingDetailRouterInput {
    private weak var viewController: UIViewController?
    private let appAssembly: AppAssembly
    
    public var isShowingAgentGenerating: Bool = false
    
    public init(viewController: UIViewController? = nil, appAssembly: AppAssembly = .shared) {
        self.viewController = viewController
        self.appAssembly = appAssembly
    }
    
    public func embedWaveformPlayback(with recording: Recording) {}
    public func embedTranscript(with recording: Recording) {}
    public func embedSummary(with recording: Recording) {}
    public func embedMindMap(with recording: Recording) {}
    
    public func didExitRecordingDetail() {}
    
    public func openAgentGenerating(with recording: Recording) {
        isShowingAgentGenerating = true
    }
}
