import SwiftMarkdownView
import SwiftUI
import DesignSystem

/// リンク要素のカタログ View。
public struct LinkCatalogView: View {

    @Environment(\.colorPalette) private var colorPalette
    @Environment(\.spacingScale) private var spacing

    public init() {}

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: spacing.xl) {
                // Overview
                CatalogSectionCard(
                    title: "概要",
                    subtitle: "ハイパーリンクを作成します"
                ) {
                    Text("`[テキスト](URL)` の形式でリンクを作成できます。テキストをクリックすると指定したURLに移動します。")
                        .typography(.bodyMedium)
                        .foregroundStyle(colorPalette.onSurfaceVariant)
                }

                // Basic link
                CatalogSectionCard(title: "基本的なリンク") {
                    MarkdownPreviewCard(
                        title: "シンプルなリンク",
                        markdownSource: "[Apple公式サイト](https://www.apple.com) を訪問してください。"
                    )
                }

                // With title
                CatalogSectionCard(title: "タイトル付きリンク") {
                    MarkdownPreviewCard(
                        title: "ツールチップ表示",
                        markdownSource: "[SwiftUI](https://developer.apple.com/xcode/swiftui/ \"SwiftUIドキュメント\") でUIを構築します。"
                    )
                }

                // Multiple links
                CatalogSectionCard(title: "複数のリンク") {
                    MarkdownPreviewCard(
                        title: "文中に複数のリンク",
                        markdownSource: """
                        詳細は [ドキュメント](https://docs.example.com) を参照してください。
                        問題がある場合は [サポート](https://support.example.com) にお問い合わせください。
                        """
                    )
                }

                // In lists
                CatalogSectionCard(title: "リスト内のリンク") {
                    MarkdownPreviewCard(
                        title: "参考リンク一覧",
                        markdownSource: """
                        - [Swift公式](https://swift.org)
                        - [SwiftUI Tutorial](https://developer.apple.com/tutorials/swiftui)
                        - [GitHub](https://github.com)
                        """
                    )
                }

                // With other inline elements
                CatalogSectionCard(title: "他のインライン要素との組み合わせ") {
                    MarkdownPreviewCard(
                        title: "太字リンク",
                        markdownSource: "**[重要なリンク](https://example.com)** をクリックしてください。"
                    )
                }

                // Link appearance
                CatalogSectionCard(title: "リンクの見た目") {
                    VStack(alignment: .leading, spacing: spacing.md) {
                        Text("リンクの色は DesignSystem の `ColorPalette` から解決されます。`primary` を差し替えると変わります:")
                            .typography(.bodyMedium)
                            .foregroundStyle(colorPalette.onSurfaceVariant)

                        CodeSnippetView(
                            code: """
                            MarkdownView(source)
                                .theme(ThemeProvider(colorPalette: MyPalette()))
                            """,
                            language: "swift"
                        )
                    }
                }

                // Usage
                CatalogSectionCard(title: "使用例") {
                    CodeSnippetView(
                        code: """
                        MarkdownView(\"\"\"
                        [詳細はこちら](https://example.com)
                        \"\"\")
                        """,
                        language: "swift"
                    )
                }
            }
            .padding(spacing.lg)
        }
        .background(colorPalette.background)
    }
}

#Preview {
    NavigationStack {
        LinkCatalogView()
            .navigationTitle("リンク")
    }
    .theme(ThemeProvider())
}
