import Foundation
import SwiftUI

public final class RecordingListRouter: RecordingListRouterInput {
    private weak var viewController: UIViewController?
    
    public init(viewController: UIViewController?) {
        self.viewController = viewController
    }
    
    public func openRecordingDetail(with recording: Recording) {
        // Navigation implementation
    }
    
    public func openDeviceSettings() {
        // Navigation implementation
    }
    
    public func openAgentGenerating() {
        // Navigation implementation
    }
}
