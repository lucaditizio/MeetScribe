import SwiftUI

/// Theme colors and styles for the Scribe app
public enum Theme {
    // MARK: - Brand Colors
    
    public static let scribeRed = Color(red: 0.9, green: 0.2, blue: 0.2)
    public static let accentGray = Color.gray
    
    // MARK: - Background Colors
    
    public static let obsidian = Color(red: 0.1, green: 0.1, blue: 0.11)
    public static let cardBackgroundLight = Color.white
    public static let cardBackgroundDark = Color(red: 0.15, green: 0.15, blue: 0.16)
    
    // MARK: - Shadow
    
    public static let shadowOpacityLight: Double = 0.1
    public static let shadowOpacityDark: Double = 0.2
    public static let shadowRadius: CGFloat = 10
    public static let cornerRadius: CGFloat = 20
    
    // MARK: - Card Background Helper
    
    public static func cardBackground(for colorScheme: ColorScheme) -> Color {
        return colorScheme == .dark ? cardBackgroundDark : cardBackgroundLight
    }
}

// MARK: - View Modifier

struct ScribeCardStyle: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    
    func body(content: Content) -> some View {
        content
            .background(Theme.cardBackground(for: colorScheme))
            .cornerRadius(20)
            .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
    }
}

extension View {
    func scribeCardStyle() -> some View {
        modifier(ScribeCardStyle())
    }
}
