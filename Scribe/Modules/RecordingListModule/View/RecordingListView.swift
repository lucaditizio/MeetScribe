import SwiftUI

/// Passive VIPER View: reads state from Presenter, forwards user actions to Presenter.
///
/// The `router` is held separately for SwiftUI's declarative navigation bindings
/// (`.navigationDestination`, `.sheet`).  The Presenter calls the router to set
/// navigation state; the View reacts to that state automatically.
public struct RecordingListView: View {

    // MARK: - Properties

    /// Presenter reference (user-action receiver + display source)
    @Bindable public var presenter: RecordingListPresenter

    /// Router — observed for navigation state changes
    @Bindable public var router: RecordingListRouter

    // MARK: - Init

    public init(presenter: RecordingListPresenter, router: RecordingListRouter) {
        self.presenter = presenter
        self.router = router
    }

    // MARK: - Body

    public var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color.black
                    .ignoresSafeArea()
                VStack(spacing: 0) {
                    // Title - fixed at top
                    Text("MeetScribe")
                        .font(.largeTitle)
                        .foregroundColor(.white)
                        .padding(.top, 12)
                        .padding(.horizontal, Spacing.contentPadding)
                    // Content
                    contentView
                        .padding(.top, 12)
                    Spacer()
                    // Bottom bar: mic indicator + record button
                    bottomBarView
                }
                .padding(.horizontal, Spacing.contentPadding)
            }
            .preferredColorScheme(.dark)
            .toolbar {
                ToolbarItemGroup(placement: .primaryAction) {
                    Button {
                        presenter.didTapSettings()
                    } label: {
                        Image(systemName: "mic.badge.plus")
                            .foregroundColor(Theme.scribeRed)
                            .font(.title2)
                    }
                }
            }
            // Push RecordingDetail onto the NavigationStack when a recording is selected
            .navigationDestination(item: $router.selectedRecording) { recording in
                router.recordingDetailView(for: recording)
            }
        }
        // DeviceSettings sheet
        .sheet(isPresented: $router.isShowingDeviceSettings) {
            router.deviceSettingsView()
        }
        // AgentGenerating sheet (shown while a recording is being processed)
        .sheet(isPresented: $router.isShowingAgentGenerating) {
            router.agentGeneratingView()
        }
        .onAppear {
            presenter.didTriggerViewReady()
        }
        .listStyle(.plain)
    }

    // MARK: - Content View

    @ViewBuilder
    private var contentView: some View {
        if presenter.state.recordings.isEmpty {
            emptyStateView
        } else {
            recordingsListView
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "mic.slash")
                .font(.system(size: 60))
                .foregroundColor(Theme.accentGray)

            Text("No recordings yet.")
                .font(.headline)
                .foregroundColor(Theme.accentGray)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Recordings List

    private var recordingsListView: some View {
        List {
            ForEach(sortedRecordings, id: \.id) { recording in
                RecordingCardView(
                    recording: recording,
                    onTap: {
                        presenter.didTapRecording(id: recording.id.uuidString)
                    }
                )
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        presenter.didDeleteRecording(id: recording.id.uuidString)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                    .tint(Theme.scribeRed)
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    // MARK: - Sorted Recordings (Passively sorted — no business logic)

    private var sortedRecordings: [Recording] {
        presenter.state.recordings.sorted { $0.createdAt > $1.createdAt }
    }

    // MARK: - Bottom Bar

    private var bottomBarView: some View {
        VStack(spacing: 12) {
            micSourceIndicator
            
            RecordButtonView(
                isRecording: presenter.state.isRecording,
                onTap: {
                    presenter.didTapRecord()
                }
            )
        }
        .padding(.bottom, 20)
    }
    
    private var micSourceIndicator: some View {
        HStack(spacing: 8) {
            Image(systemName: "mic.fill")
                .font(.caption)
            Text(presenter.state.micSource)
                .font(.caption)
                .textCase(.uppercase)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Theme.cardBackgroundDark)
        .cornerRadius(16)
        .foregroundColor(Theme.accentGray)
    }
}
