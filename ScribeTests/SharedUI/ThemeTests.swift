import XCTest
import SwiftUI
@testable import Scribe

final class ThemeTests: XCTestCase {
    func testThemeColorsExist() {
        XCTAssertNotNil(Theme.scribeRed)
        XCTAssertNotNil(Theme.accentGray)
        XCTAssertNotNil(Theme.obsidian)
        XCTAssertNotNil(Theme.cardBackgroundLight)
        XCTAssertNotNil(Theme.cardBackgroundDark)
    }
    
    func testThemeConstants() {
        XCTAssertEqual(Theme.cornerRadius, 20)
        XCTAssertEqual(Theme.shadowRadius, 10)
        XCTAssertEqual(Theme.shadowOpacityLight, 0.1)
        XCTAssertEqual(Theme.shadowOpacityDark, 0.2)
    }
    
    func testCardBackgroundHelper() {
        let lightBackground = Theme.cardBackground(for: .light)
        let darkBackground = Theme.cardBackground(for: .dark)
        
        XCTAssertNotNil(lightBackground)
        XCTAssertNotNil(darkBackground)
    }
    
    func testScribeCardStyleModifier() {
        let view = Text("Test").scribeCardStyle()
        XCTAssertNotNil(view)
    }
    
    func testSpacingValues() {
        XCTAssertEqual(Spacing.recordButtonOuterSize, 80)
        XCTAssertEqual(Spacing.recordButtonInnerSize, 70)
        XCTAssertEqual(Spacing.waveformBarCount, 50)
        XCTAssertEqual(Spacing.waveformBarSpacing, 3)
    }
    
    func testTypographyStyles() {
        XCTAssertNotNil(Typography.largeTitle)
        XCTAssertNotNil(Typography.title)
        XCTAssertNotNil(Typography.body)
    }
}
