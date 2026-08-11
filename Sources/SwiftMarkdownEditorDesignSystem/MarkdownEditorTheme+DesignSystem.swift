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
    ///   - baseFontSize: The point size of body text, which heading sizes scale from.
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
    ///     .markdownEditorDesignSystemTheme(baseFontSize: 20)
    /// ```
    ///
    /// - Parameter baseFontSize: The point size of body text, which the editor below takes
    ///   along with the derived colors.
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
