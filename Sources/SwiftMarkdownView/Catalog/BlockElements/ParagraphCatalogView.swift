import SwiftUI
import DesignSystem

/// Catalog view for paragraph elements.
public struct ParagraphCatalogView: View {

    @Environment(\.colorPalette) private var colorPalette
    @Environment(\.spacingScale) private var spacing

    public init() {}

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: spacing.xl) {
                // Overview
                CatalogSectionCard(
                    title: "概要",
                    subtitle: "段落は最も基本的なテキストブロックです"
                ) {
                    Text("空行で区切られたテキストは個別の段落として扱われます。段落内では改行は無視され、連続したテキストとして表示されます。")
                        .typography(.bodyMedium)
                        .foregroundStyle(colorPalette.onSurfaceVariant)
                }

                // Single paragraph
                CatalogSectionCard(title: "基本的な段落") {
                    MarkdownPreviewCard(
                        title: "シンプルな段落",
                        markdownSource: "これは基本的な段落です。Markdownでは、テキストをそのまま入力するだけで段落になります。"
                    )
                }

                // Multiple paragraphs
                CatalogSectionCard(title: "複数の段落") {
                    MarkdownPreviewCard(
                        title: "空行で区切る",
                        description: "空行を入れると新しい段落になります",
                        markdownSource: """
                        これは最初の段落です。ここに文章を書きます。

                        これは2番目の段落です。空行で区切られています。

                        これは3番目の段落です。
                        """
                    )
                }

                // With inline elements
                CatalogSectionCard(title: "インライン要素を含む段落") {
                    MarkdownPreviewCard(
                        title: "装飾付きテキスト",
                        markdownSource: "段落には**太字**や*斜体*、`インラインコード`、[リンク](https://example.com)などのインライン要素を含めることができます。"
                    )
                }

                // Usage
                CatalogSectionCard(title: "使用例") {
                    CodeSnippetView(
                        code: """
                        MarkdownView(\"\"\"
                        最初の段落のテキスト。

                        2番目の段落には**太字**が含まれています。
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
        ParagraphCatalogView()
            .navigationTitle("段落")
    }
    .theme(ThemeProvider())
}
