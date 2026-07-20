import SwiftMarkdownView
import SwiftUI
import DesignSystem

/// Markdown カタログのメインエントリーポイント。
///
/// Markdown の全要素・スタイル・設定オプションをライブプレビュー付きで網羅するカタログを表示する。
///
/// 画面サイズに応じて自動的にレイアウトを切り替える:
/// - Regular 横幅クラス: 3カラム NavigationSplitView
/// - Compact 横幅クラス: NavigationStack ベースのリスト
///
/// ## 基本的な使い方
///
/// ```swift
/// struct ContentView: View {
///     var body: some View {
///         MarkdownCatalogView()
///             .theme(ThemeProvider())
///     }
/// }
/// ```
///
/// ## シンタックスハイライトを有効にする
///
/// カタログ内のすべてのコード例でシンタックスハイライトを有効にするには、
/// `SwiftMarkdownViewHighlightJS` モジュールを使用する:
///
/// ```swift
/// import SwiftMarkdownViewHighlightJS
///
/// struct ContentView: View {
///     var body: some View {
///         MarkdownCatalogView()
///             .theme(ThemeProvider())
///             .adaptiveSyntaxHighlighting()
///     }
/// }
/// ```
///
/// カタログ全体のコードスニペットにシンタックスハイライトを適用し、
/// ライト/ダークモードを自動検出する。
public struct MarkdownCatalogView: View {

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    public init() {}

    public var body: some View {
        if horizontalSizeClass == .regular {
            MarkdownCatalogSplitView()
        } else {
            MarkdownCatalogListView()
        }
    }
}

#Preview {
    MarkdownCatalogView()
        .theme(ThemeProvider())
}
