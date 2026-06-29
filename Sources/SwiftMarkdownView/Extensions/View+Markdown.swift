import SwiftUI
import DesignSystem

// MARK: - View Extensions for MarkdownView

public extension View {

    /// MarkdownView とそのコンテンツに DesignSystem テーマを適用する。
    ///
    /// このモディファイアにより、すべての Markdown 要素が DesignSystem テーマの
    /// タイポグラフィ・カラー・スペーシングを使用する。
    ///
    /// ```swift
    /// MarkdownView(source)
    ///     .markdownTheme(themeProvider)
    /// ```
    ///
    /// - Parameter provider: テーマ設定を保持する ThemeProvider。
    /// - Returns: テーマが適用されたビュー。
    func markdownTheme(_ provider: ThemeProvider) -> some View {
        self.theme(provider)
    }
}

