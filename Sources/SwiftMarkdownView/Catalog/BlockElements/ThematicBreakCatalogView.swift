import SwiftUI
import DesignSystem

/// Catalog view for thematic break (horizontal rule) elements.
public struct ThematicBreakCatalogView: View {

    @Environment(\.colorPalette) private var colorPalette
    @Environment(\.spacingScale) private var spacing

    public init() {}

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: spacing.xl) {
                // Overview
                CatalogSectionCard(
                    title: "概要",
                    subtitle: "水平線はセクションの区切りを示します"
                ) {
                    Text("`---`、`***`、`___` のいずれか（3つ以上）で水平線を作成できます。コンテンツの区切りやトピックの変更を視覚的に示すために使用します。")
                        .typography(.bodyMedium)
                        .foregroundStyle(colorPalette.onSurfaceVariant)
                }

                // Different syntaxes
                CatalogSectionCard(title: "構文のバリエーション") {
                    VStack(alignment: .leading, spacing: spacing.lg) {
                        MarkdownPreviewCard(
                            title: "ハイフン (---)",
                            markdownSource: """
                            上のセクション

                            ---

                            下のセクション
                            """
                        )

                        MarkdownPreviewCard(
                            title: "アスタリスク (***)",
                            markdownSource: """
                            上のセクション

                            ***

                            下のセクション
                            """
                        )

                        MarkdownPreviewCard(
                            title: "アンダースコア (___)",
                            markdownSource: """
                            上のセクション

                            ___

                            下のセクション
                            """
                        )
                    }
                }

                // Use case
                CatalogSectionCard(title: "使用例") {
                    MarkdownPreviewCard(
                        title: "ドキュメントの区切り",
                        markdownSource: """
                        ## 第1章

                        ここに第1章の内容が入ります。

                        ---

                        ## 第2章

                        ここに第2章の内容が入ります。
                        """
                    )
                }

                // Code example
                CatalogSectionCard(title: "コード例") {
                    CodeSnippetView(
                        code: """
                        MarkdownView(\"\"\"
                        セクション1

                        ---

                        セクション2
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
        ThematicBreakCatalogView()
            .navigationTitle("水平線")
    }
    .theme(ThemeProvider())
}
