import SwiftUI
import SwiftData

/// Passive VIPER View: reads state from Presenter, forwards user actions to Presenter
public struct TranscriptTabView: View {
    // MARK: - Properties
    
    /// Strong reference to Presenter (output)
    public var output: TranscriptViewOutput
    
    /// State from Presenter (read-only, updated via Presenter)
    @State internal var state: TranscriptState
    
    // MARK: - Init
    
    public init(output: TranscriptViewOutput) {
        self.output = output
        self._state = State(initialValue: TranscriptState())
    }
    
    // MARK: - Body
    
    public var body: some View {
        ZStack {
            // Background
            Theme.obsidian
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                if state.segments.isEmpty {
                    emptyStateView
                } else {
                    transcriptListView
                }
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            output.didTriggerViewReady()
        }
        .alert("Rename Speaker", isPresented: Binding(
            get: { state.selectedSpeakerForRename != nil },
            set: { if !$0 { state.selectedSpeakerForRename = nil } }
        )) {
            TextField("Speaker name", text: .constant(""))
            Button("Cancel", role: .cancel) {
                state.selectedSpeakerForRename = nil
            }
            Button("Rename") {
                // Presenter handles the rename logic
                state.selectedSpeakerForRename = nil
            }
        } message: {
            if let speakerId = state.selectedSpeakerForRename {
                Text("Rename speaker \(speakerId)")
            }
        }
    }
    
    // MARK: - Content View
    
    @ViewBuilder
    private var transcriptListView: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: Spacing.sectionSpacing) {
                ForEach(state.segments, id: \.id) { segment in
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
                    output.didTapSpeaker(speakerId: segment.speakerId)
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