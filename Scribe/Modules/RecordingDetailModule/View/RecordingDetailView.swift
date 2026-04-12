import SwiftUI

public struct RecordingDetailView: View {
    @Bindable var presenter: RecordingDetailPresenter
    
    public init(presenter: RecordingDetailPresenter) {
        self.presenter = presenter
    }
    
    public var body: some View {
        ZStack {
            Theme.obsidian
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                pickerView
                    .padding(.top, 16)
                    .padding(.horizontal, Spacing.contentPadding)
                
                ScrollView {
                    VStack(spacing: Spacing.sectionSpacing) {
                        recordingHeaderView
                        
                        if let waveformPresenter = presenter.waveformPresenter {
                            WaveformPlaybackView(presenter: waveformPresenter)
                        }
                        
                        tabContentView
                    }
                    .padding(.horizontal, Spacing.contentPadding)
                    .padding(.vertical, Spacing.sectionSpacing)
                }
            }
            
            if !presenter.state.hasTranscript {
                VStack {
                    Spacer()
                    generateTranscriptCTA
                        .padding(.bottom, 32)
                }
            }
        }
        .navigationTitle("Recording")
        .navigationBarTitleDisplayMode(.automatic)
        .preferredColorScheme(.dark)
        .onDisappear {
            presenter.didExitRecordingDetail()
        }
    }
    
    @State private var selectedTabBinding: RecordingDetailTab = .summary
    
    private var pickerView: some View {
        Picker("Tab", selection: $selectedTabBinding) {
            Text("Summary").tag(RecordingDetailTab.summary)
            Text("Transcript").tag(RecordingDetailTab.transcript)
            Text("Mind Map").tag(RecordingDetailTab.mindMap)
        }
        .pickerStyle(.segmented)
    }
    
    private var recordingHeaderView: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let recording = presenter.state.recording {
                Text(recording.title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                HStack(spacing: 12) {
                    Text(formattedDate(recording.date))
                        .font(.caption)
                        .foregroundColor(Theme.accentGray)
                    
                    Text("•")
                        .foregroundColor(Theme.accentGray)
                    
                    Text(formattedDuration(recording.duration))
                        .font(.caption)
                        .foregroundColor(Theme.accentGray)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    @ViewBuilder
    private var tabContentView: some View {
        switch presenter.state.selectedTab {
        case .summary:
            summaryContentView
        case .transcript:
            transcriptContentView
        case .mindMap:
            mindMapContentView
        }
    }
    
    private var summaryContentView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Summary")
                .font(.headline)
                .foregroundColor(.white)
            
            if let recording = presenter.state.recording {
                Text(recording.meetingNotes ?? "No summary available yet.")
                    .font(.body)
                    .foregroundColor(Theme.accentGray)
            } else {
                Text("No summary available yet.")
                    .font(.body)
                    .foregroundColor(Theme.accentGray)
            }
        }
        .padding(Spacing.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.cardBackgroundDark)
        .cornerRadius(Theme.cornerRadius)
    }
    
    private var transcriptContentView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Transcript")
                .font(.headline)
                .foregroundColor(.white)
            
            if let recording = presenter.state.recording {
                Text(recording.rawTranscript.isEmpty ? "No transcript available yet.\nTap the button below to generate one." : recording.rawTranscript)
                    .font(.body)
                    .foregroundColor(Theme.accentGray)
            } else {
                Text("No transcript available yet.\nTap the button below to generate one.")
                    .font(.body)
                    .foregroundColor(Theme.accentGray)
            }
        }
        .padding(Spacing.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.cardBackgroundDark)
        .cornerRadius(Theme.cornerRadius)
    }
    
    private var mindMapContentView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Mind Map")
                .font(.headline)
                .foregroundColor(.white)
            
            if let recording = presenter.state.recording, let actionItems = recording.actionItems {
                Text(actionItems)
                    .font(.body)
                    .foregroundColor(Theme.accentGray)
            } else {
                Text("No mind map available yet.")
                    .font(.body)
                    .foregroundColor(Theme.accentGray)
            }
        }
        .padding(Spacing.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.cardBackgroundDark)
        .cornerRadius(Theme.cornerRadius)
    }
    
    private var generateTranscriptCTA: some View {
        Button {
            presenter.didTapGenerateTranscript()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "waveform")
                    .font(.caption)
                Text("Generate Transcript")
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Theme.scribeRed)
            .foregroundColor(.white)
            .cornerRadius(25)
        }
        .shadow(color: Theme.scribeRed.opacity(0.4), radius: 10, x: 0, y: 5)
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func formattedDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

private final class PassthroughWaveformOutput: WaveformPlaybackViewOutput {
    let onViewReady: () -> Void
    let onPlayPause: () -> Void
    let onSkipForward: () -> Void
    let onSkipBackward: () -> Void
    let onSeek: (TimeInterval) -> Void
    let onTapSpeed: () -> Void
    
    init(
        onViewReady: @escaping () -> Void,
        onPlayPause: @escaping () -> Void,
        onSkipForward: @escaping () -> Void,
        onSkipBackward: @escaping () -> Void,
        onSeek: @escaping (TimeInterval) -> Void,
        onTapSpeed: @escaping () -> Void
    ) {
        self.onViewReady = onViewReady
        self.onPlayPause = onPlayPause
        self.onSkipForward = onSkipForward
        self.onSkipBackward = onSkipBackward
        self.onSeek = onSeek
        self.onTapSpeed = onTapSpeed
    }
    
    func didTriggerViewReady() { onViewReady() }
    func didTapPlayPause() { onPlayPause() }
    func didTapSkipForward() { onSkipForward() }
    func didTapSkipBackward() { onSkipBackward() }
    func didSeek(to time: TimeInterval) { onSeek(time) }
    func didTapSpeed() { onTapSpeed() }
}

extension RecordingDetailState {
    var hasTranscript: Bool {
        guard let recording = recording else { return false }
        return !recording.rawTranscript.isEmpty || recording.transcript != nil
    }
}