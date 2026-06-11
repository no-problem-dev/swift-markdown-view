#if canImport(UIKit)
import SwiftUI
import VisualTesting

/// Configures the VisualTesting environment for the editor snapshot suite.
@MainActor
func setupVisualTesting() {
    VisualTesting.themeApplicable = DefaultThemeApplicable()
}
#endif
