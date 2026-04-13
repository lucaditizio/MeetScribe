import SwiftUI
import Combine

/// Navigation router for RecordingListModule.
///
/// SwiftUI drives navigation declaratively, so the router publishes
/// destination state that `RecordingListView` observes via `.navigationDestination`
/// and `.sheet` modifiers.  The `AppAssembly` reference lets the router
/// build real module views without taking on any business logic.
@Observable
public final class RecordingListRouter: RecordingListRouterInput {

    // MARK: - Navigation State (observed by RecordingListView)

    /// The recording whose detail screen should be pushed onto the NavigationStack.
    public var selectedRecording: Recording?

    /// Controls DeviceSettings sheet presentation.
    public var isShowingDeviceSettings: Bool = false

    // MARK: - Dependencies
    private weak var viewController: UIViewController?
    private let appAssembly: AppAssembly

    // MARK: - Initialization
    public init(viewController: UIViewController? = nil, appAssembly: AppAssembly) {
        self.viewController = viewController
        self.appAssembly = appAssembly
    }

    // MARK: - RecordingListRouterInput

    public func openRecordingDetail(with recording: Recording) {
        selectedRecording = recording
    }

    public func openDeviceSettings() {
        isShowingDeviceSettings = true
    }

    // MARK: - View Factories (called from RecordingListView sheet/navigation bodies)

    @ViewBuilder
    public func recordingDetailView(for recording: Recording) -> some View {
        appAssembly.makeRecordingDetailModule(recordingId: recording.id, output: nil)
    }

    @ViewBuilder
    public func deviceSettingsView() -> some View {
        appAssembly.makeDeviceSettingsModule(output: nil)
    }
}
