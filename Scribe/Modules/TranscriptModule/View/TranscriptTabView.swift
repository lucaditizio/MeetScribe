import SwiftUI
import SwiftData

/// SwiftUI-native VIPER View: binds to Presenter for state and actions
public struct TranscriptTabView: View {
    // MARK: - Properties
    
    /// Bindable presenter - provides state and handles actions
    @Bindable var presenter: TranscriptPresenter
    
    // MARK: - Init
    
    public init(presenter: TranscriptPresenter) {
        self.presenter = presenter
    }
    
    // MARK: - Body
    
    public var body: some View {
        ZStack {
            // Background
            Theme.obsidian
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                if presenter.state.segments.isEmpty {
                    emptyStateView
                } else {
                    transcriptListView
                }
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            presenter.didTriggerViewReady()
        }
        .alert("Rename Speaker", isPresented: Binding(
            get: { presenter.state.selectedSpeakerForRename != nil },
            set: { if !$0 { presenter.didCancelRename() } }
        )) {
            TextField("Speaker name", text: .constant(""))
            Button("Cancel", role: .cancel) {
                presenter.didCancelRename()
            }
            Button("Rename") {
                // Presenter handles the rename logic
                presenter.didConfirmRename()
            }
        } message: {
            if let speakerId = presenter.state.selectedSpeakerForRename {
                Text("Rename speaker \(speakerId)")
            }
        }
    }
    
    // MARK: - Content View
    
    @ViewBuilder
    private var transcriptListView: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: Spacing.sectionSpacing) {
                ForEach(presenter.state.segments, id: \.id) { segment in
                    transcriptSegmentView(segment: segment)
                }
            }
            .padding(Spacing.cardPadding)
        }
    }
    
    // MARK: - Segment View
    
    private func transcriptSegmentView(segment: SpeakerSegment) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            // Speaker label with timestamp
            HStack {
                Button {
                    presenter.didTapSpeaker(speakerId: segment.speakerId)
                } label: {
                    HStack(spacing: 4) {
                        Text(segment.speakerName)
                            .font(Typography.headline)
                            .foregroundColor(Theme.scribeRed)
                        
                        Text("- \(formatTime(segment.start))")
                            .font(Typography.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
            }
            
            // Transcript text content
            Text(segment.text)
                .font(Typography.body)
                .foregroundColor(.primary)
                .textSelection(.enabled)
        }
        .padding(Spacing.contentPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.cardBackgroundDark)
        .cornerRadius(Theme.cornerRadius)
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 60))
                .foregroundColor(Theme.accentGray)
            
            Text("No transcript available")
                .font(Typography.headline)
                .foregroundColor(Theme.accentGray)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Helpers
    
    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}