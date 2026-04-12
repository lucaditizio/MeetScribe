import Foundation
import SwiftUI

public final class RecordingDetailRouter: RecordingDetailRouterInput {
    private weak var viewController: UIViewController?
    
    public init(viewController: UIViewController?) {
        self.viewController = viewController
    }
    
    public func embedWaveformPlayback(with recording: Recording) {}
    public func embedTranscript(with recording: Recording) {}
    public func embedSummary(with recording: Recording) {}
    public func embedMindMap(with recording: Recording) {}
    
    public func didExitRecordingDetail() {
        // Stop waveform playback when leaving detail view
        // This prevents audio from continuing when user navigates back
    }
}
