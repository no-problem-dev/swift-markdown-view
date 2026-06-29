import SwiftUI
import DesignSystem
import SwiftMarkdownEditorTextKit

public extension MarkdownEditorTheme {

    /// デザインシステムのカラーパレットからエディタテーマを構築する。
    /// これによりソースエディタの着色がアプリテーマと常に同期する。
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
