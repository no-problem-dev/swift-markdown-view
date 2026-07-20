import SwiftUI
import DesignSystem
import SwiftMarkdownEditor
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

extension View {

    /// 環境の DesignSystem パレットからエディタテーマを導出して適用する。
    ///
    /// ```swift
    /// MarkdownEditor(text: $text)
    ///     .markdownEditorDesignSystemTheme()
    /// ```
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
