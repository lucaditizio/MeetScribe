import SwiftUI

public struct WaveformPlaybackView: View {
    // MARK: - Properties
    
    @Bindable var presenter: WaveformPlaybackPresenter
    
    // MARK: - Init
    
    public init(presenter: WaveformPlaybackPresenter) {
        self.presenter = presenter
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
            presenter.didTriggerViewReady()
        }
    }
    
    // MARK: - Waveform Visualization
    
    private var waveformView: some View {
        HStack(spacing: Spacing.waveformBarSpacing) {
            ForEach(0..<Spacing.waveformBarCount, id: \.self) { index in
                WaveformBar(
                    index: index,
                    totalBars: Spacing.waveformBarCount,
                    state: presenter.state
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
                presenter.didTapSkipBackward()
            } label: {
                Image(systemName: "gobackward.15")
                    .font(.title2)
                    .foregroundColor(Theme.accentGray)
            }
            .frame(width: 44, height: 44)
            
            // Play/Pause
            Button {
                presenter.didTapPlayPause()
            } label: {
                Image(systemName: presenter.state.isPlaying ? "pause.fill" : "play.fill")
                    .font(.title)
                    .foregroundColor(.white)
                    .frame(width: Spacing.playbackButtonSize, height: Spacing.playbackButtonSize)
                    .background(Theme.scribeRed)
                    .clipShape(Circle())
            }
            
            // Skip forward 15s
            Button {
                presenter.didTapSkipForward()
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
            presenter.didTapSpeed()
        } label: {
            Text("\(presenter.state.speed, specifier: "%.1f")x")
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