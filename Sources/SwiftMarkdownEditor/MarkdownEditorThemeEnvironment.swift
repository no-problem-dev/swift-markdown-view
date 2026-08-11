import SwiftUI
import SwiftMarkdownEditorTextKit

private struct MarkdownEditorThemeKey: EnvironmentKey {
    // `MarkdownEditorTheme` holds a PlatformColor and so is not Sendable. A stored
    // property would be rejected as a mutable global, so build the value each time.
    static var defaultValue: MarkdownEditorTheme { .light }
}

extension EnvironmentValues {

    /// The theme that colors and sizes the source editor.
    ///
    /// The default, `MarkdownEditorTheme.light`, is built from system semantic
    /// colors and follows light and dark appearance on its own. Replace it to match
    /// an app-specific palette, or to edit at another body text size.
    public var markdownEditorTheme: MarkdownEditorTheme {
        get { self[MarkdownEditorThemeKey.self] }
        set { self[MarkdownEditorThemeKey.self] = newValue }
    }
}

extension View {

    /// Sets the theme for source editors in this view hierarchy.
    ///
    /// - Parameter theme: The theme to apply. ``MarkdownEditor`` takes it whole — its
    ///   colors and its `baseFontSize` alike.
    public func markdownEditorTheme(_ theme: MarkdownEditorTheme) -> some View {
        environment(\.markdownEditorTheme, theme)
    }
}
