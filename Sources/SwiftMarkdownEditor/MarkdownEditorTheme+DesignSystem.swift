import SwiftUI
import DesignSystem
import SwiftMarkdownEditorTextKit

public extension MarkdownEditorTheme {

    /// Builds an editor theme from a design-system color palette, so the source
    /// editor's tints stay in lock-step with the app theme.
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
