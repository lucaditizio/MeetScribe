import SwiftUI

/// Passive VIPER View: reads state from Presenter, forwards user actions to Presenter
public struct RecordingListView: View {
    // MARK: - Properties
    
    /// Strong reference to Presenter (output)
    public var output: RecordingListViewOutput
    
    /// State from Presenter (read-only, updated via Presenter)
    @State private var state: RecordingListState
    
    // MARK: - Init
    
    public init(output: RecordingListViewOutput) {
        self.output = output
        self._state = State(initialValue: RecordingListState())
    }
    
    // MARK: - Body
    
    public var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color.black
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Content
                    contentView
                        .padding(.top, 20)
                    
                    Spacer()
                    
                    // Bottom bar: mic indicator + record button
                    bottomBarView
                }
                .padding(.horizontal, Spacing.contentPadding)
            }
            .navigationTitle("MeetScribe")
            .navigationBarTitleDisplayMode(.large)
            .preferredColorScheme(.dark)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        output.didTapRecord()
                    } label: {
                        Image(systemName: "mic.badge.plus")
                            .foregroundColor(Theme.scribeRed)
                            .font(.title2)
                    }
                }
            }
        }
        .listStyle(.plain)
    }
    
    // MARK: - Content View
    
    @ViewBuilder
    private var contentView: some View {
        if state.recordings.isEmpty {
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
        ScrollView {
            LazyVStack(spacing: Spacing.sectionSpacing) {
                ForEach(sortedRecordings, id: \.id) { recording in
                    RecordingCardView(
                        recording: recording,
                        onTap: {
                            output.didTapRecording(id: recording.id.uuidString)
                        },
                        onDelete: {
                            output.didDeleteRecording(id: recording.id.uuidString)
                        }
                    )
                }
            }
            .padding(.vertical, Spacing.sectionSpacing)
        }
    }
    
    // MARK: - Sorted Recordings (Passively sorted - no business logic)
    
    private var sortedRecordings: [Recording] {
        state.recordings.sorted { $0.createdAt > $1.createdAt }
    }
    
    // MARK: - Bottom Bar
    
    private var bottomBarView: some View {
        HStack {
            // Mic source indicator badge
            HStack(spacing: 8) {
                Image(systemName: "mic.fill")
                    .font(.caption)
                Text(state.micSource)
                    .font(.caption)
                    .textCase(.uppercase)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Theme.cardBackgroundDark)
            .cornerRadius(16)
            .foregroundColor(Theme.accentGray)
            
            Spacer()
            
            // Record button
            RecordButtonView(
                isRecording: state.isRecording,
                onTap: {
                    output.didTapRecord()
                }
            )
        }
        .padding(.bottom, 20)
        .padding(.horizontal, Spacing.contentPadding)
    }
}



