#if canImport(UIKit)
import SwiftUI
import VisualTesting

/// Setup function for VisualTesting configuration.
///
/// Configures the snapshot test environment:
/// - Device: iPhone 16 only
/// - Themes: Light + Dark
/// - Locale: Japanese only
@MainActor
func setupVisualTesting() {
    VisualTesting.themeApplicable = DefaultThemeApplicable()
}
#endif
