import Foundation

/// Hardcoded spacing values extracted from current views
public enum Spacing {
    // MARK: - Recording Button
    public static let recordButtonOuterSize: CGFloat = 80
    public static let recordButtonInnerSize: CGFloat = 70
    
    // MARK: - Waveform
    public static let waveformBarCount: Int = 50
    public static let waveformBarSpacing: CGFloat = 3
    public static let waveformBarCornerRadius: CGFloat = 2
    public static let waveformBarMinHeight: CGFloat = 4
    
    // MARK: - Playback Controls
    public static let skipButtonSeconds: Int = 15
    public static let playbackButtonSize: CGFloat = 44
    
    // MARK: - Dashboard/Layout
    public static let cardPadding: CGFloat = 16
    public static let sectionSpacing: CGFloat = 20
    public static let contentPadding: CGFloat = 12
}
