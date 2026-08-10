import SwiftUI
import DesignSystem
import SwiftMarkdownEditor
import SwiftMarkdownEditorTextKit

public extension MarkdownEditorTheme {

    /// Builds an editor theme from a design system color palette.
    ///
    /// The roles map straight across: `onSurface` becomes the text color, `surface` the
    /// background, `onSurfaceVariant` the muted syntax markers, `secondary` the code
    /// color, and `primary` both the accent and the caret tint.
    ///
    /// - Parameters:
    ///   - palette: The palette to read colors from.
    ///   - baseFontSize: The point size of body text. It applies when the theme drives
    ///     `MarkdownSourceTextView` directly. `MarkdownEditor` overrides it with the
    ///     `baseFontSize` of its own initializer, so set the editor's font size there.
    static func fromDesignSystem(
        palette: any ColorPalette,
        baseFontSize: CGFloat = 16
    ) -> MarkdownEditorTheme {
        .make(
            baseFontSize: baseFontSize,
            textColor: PlatformColor(palette.onSurface),
            backgroundColor: PlatformColor(palette.surface),
            muted: PlatformColor(palette.onSurfaceVariant),
            accent: PlatformColor(palette.primary),
            code: PlatformColor(palette.secondary)
        )
    }
}

extension View {

    /// Derives an editor theme from the design system palette in the environment.
    ///
    /// ```swift
    /// MarkdownEditor(text: $text)
    ///     .markdownEditorDesignSystemTheme()
    /// ```
    ///
    /// - Parameter baseFontSize: The point size of body text. It applies when the
    ///   derived theme drives `MarkdownSourceTextView` directly. `MarkdownEditor`
    ///   overrides it with the `baseFontSize` of its own initializer, so
    ///   `MarkdownEditor(text: $text).markdownEditorDesignSystemTheme(baseFontSize: 20)`
    ///   still renders at the editor's own size — set the size on the editor instead.
    public func markdownEditorDesignSystemTheme(baseFontSize: CGFloat = 16) -> some View {
        modifier(DesignSystemEditorThemeBridge(baseFontSize: baseFontSize))
    }
}

private struct DesignSystemEditorThemeBridge: ViewModifier {

    let baseFontSize: CGFloat

    @Environment(\.colorPalette) private var palette

    func body(content: Content) -> some View {
        content.markdownEditorTheme(
            .fromDesignSystem(palette: palette, baseFontSize: baseFontSize)
        )
    }
}
