import SwiftUI

/// Passive VIPER View: reads state from Presenter, forwards user actions to Presenter
public struct WaveformPlaybackView: View {
    // MARK: - Properties
    
    /// Strong reference to Presenter (output)
    public var output: WaveformPlaybackViewOutput
    
    /// State from Presenter (read-only, updated via Presenter)
    @State private var state: WaveformPlaybackState
    
    // MARK: - Init
    
    public init(output: WaveformPlaybackViewOutput) {
        self.output = output
        self._state = State(initialValue: WaveformPlaybackState())
    }
    
    // MARK: - Body
    
    public var body: some View {
        VStack(spacing: Spacing.cardPadding) {
            // Waveform visualization (50 bars)
            waveformView
            
            // Playback controls
            controlsView
            
            // Speed capsule
            speedCapsuleView
        }
        .padding(Spacing.cardPadding)
        .background(Theme.cardBackgroundDark)
        .cornerRadius(Theme.cornerRadius)
        .onAppear {
            output.didTriggerViewReady()
        }
    }
    
    // MARK: - Waveform Visualization
    
    private var waveformView: some View {
        HStack(spacing: Spacing.waveformBarSpacing) {
            ForEach(0..<Spacing.waveformBarCount, id: \.self) { index in
                WaveformBar(
                    index: index,
                    totalBars: Spacing.waveformBarCount,
                    state: state
                )
            }
        }
        .frame(height: 60)
    }
    
    // MARK: - Playback Controls
    
    private var controlsView: some View {
        HStack(spacing: 32) {
            // Skip backward 15s
            Button {
                output.didTapSkipBackward()
            } label: {
                Image(systemName: "gobackward.15")
                    .font(.title2)
                    .foregroundColor(Theme.accentGray)
            }
            .frame(width: 44, height: 44)
            
            // Play/Pause
            Button {
                output.didTapPlayPause()
            } label: {
                Image(systemName: state.isPlaying ? "pause.fill" : "play.fill")
                    .font(.title)
                    .foregroundColor(.white)
                    .frame(width: Spacing.playbackButtonSize, height: Spacing.playbackButtonSize)
                    .background(Theme.scribeRed)
                    .clipShape(Circle())
            }
            
            // Skip forward 15s
            Button {
                output.didTapSkipForward()
            } label: {
                Image(systemName: "goforward.15")
                    .font(.title2)
                    .foregroundColor(Theme.accentGray)
            }
            .frame(width: 44, height: 44)
        }
    }
    
    // MARK: - Speed Capsule
    
    private var speedCapsuleView: some View {
        Button {
            output.didTapSpeed()
        } label: {
            Text("\(state.speed, specifier: "%.1f")x")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(Theme.scribeRed)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Theme.scribeRed.opacity(0.15))
                .cornerRadius(16)
        }
    }
}

// MARK: - Waveform Bar

private struct WaveformBar: View {
    let index: Int
    let totalBars: Int
    let state: WaveformPlaybackState
    
    var body: some View {
        let progress = state.duration > 0 ? state.currentTime / state.duration : 0
        let barProgress = Double(index) / Double(totalBars)
        let isPlayed = barProgress <= progress
        
        let height: CGFloat = {
            guard !state.waveformBars.isEmpty else {
                return barHeight(for: barProgress)
            }
            let barIndex = min(index, state.waveformBars.count - 1)
            return barHeight(for: CGFloat(state.waveformBars[barIndex]))
        }()
        
        RoundedRectangle(cornerRadius: Spacing.waveformBarCornerRadius)
            .fill(isPlayed ? Theme.scribeRed : Theme.scribeRed.opacity(0.3))
            .frame(width: 3, height: max(height, Spacing.waveformBarMinHeight))
    }
    
    private func barHeight(for normalized: CGFloat) -> CGFloat {
        let minHeight = Spacing.waveformBarMinHeight
        let maxHeight: CGFloat = 56
        return minHeight + (maxHeight - minHeight) * normalized
    }
}