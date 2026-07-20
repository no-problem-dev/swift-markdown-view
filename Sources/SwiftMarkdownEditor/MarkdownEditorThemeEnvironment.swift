import SwiftUI
import SwiftMarkdownEditorTextKit

private struct MarkdownEditorThemeKey: EnvironmentKey {
    // `MarkdownEditorTheme` は PlatformColor を持つため非 Sendable。格納プロパティにすると
    // 可変グローバルとして拒否されるので、毎回組み立てる計算プロパティにする。
    static var defaultValue: MarkdownEditorTheme { .light }
}

extension EnvironmentValues {

    /// ソースエディタの着色に使うテーマ。
    ///
    /// 既定の ``MarkdownEditorTheme/light`` はシステムの意味色で構成されており、
    /// ライト/ダークに自動追従する。アプリ固有の配色に合わせたい場合だけ差し替える。
    public var markdownEditorTheme: MarkdownEditorTheme {
        get { self[MarkdownEditorThemeKey.self] }
        set { self[MarkdownEditorThemeKey.self] = newValue }
    }
}

extension View {

    /// このビュー階層のソースエディタに着色テーマを設定する。
    ///
    /// - Parameter theme: 使用するエディタテーマ。
    /// - Returns: テーマが適用されたビュー。
    public func markdownEditorTheme(_ theme: MarkdownEditorTheme) -> some View {
        environment(\.markdownEditorTheme, theme)
    }
}
