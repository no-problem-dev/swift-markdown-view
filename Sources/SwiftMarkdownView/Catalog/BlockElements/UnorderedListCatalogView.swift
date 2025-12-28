import SwiftUI
import DesignSystem

/// Catalog view for unordered (bulleted) list elements.
public struct UnorderedListCatalogView: View {

    @Environment(\.colorPalette) private var colorPalette
    @Environment(\.spacingScale) private var spacing

    public init() {}

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: spacing.xl) {
                // Overview
                CatalogSectionCard(
                    title: "概要",
                    subtitle: "順序なしリストは項目の羅列に使用します"
                ) {
                    Text("`-`、`*`、`+` のいずれかで始まる行がリストアイテムになります。インデントでネストしたリストを作成できます。")
                        .typography(.bodyMedium)
                        .foregroundStyle(colorPalette.onSurfaceVariant)
                }

                // Basic list
                CatalogSectionCard(title: "基本的なリスト") {
                    MarkdownPreviewCard(
                        title: "シンプルなリスト",
                        markdownSource: """
                        - アイテム1
                        - アイテム2
                        - アイテム3
                        """
                    )
                }

                // Different markers
                CatalogSectionCard(title: "マーカーの種類") {
                    VStack(alignment: .leading, spacing: spacing.lg) {
                        MarkdownPreviewCard(
                            title: "ハイフン (-)",
                            markdownSource: """
                            - ハイフンで始まるアイテム
                            - 2番目のアイテム
                            """
                        )

                        MarkdownPreviewCard(
                            title: "アスタリスク (*)",
                            markdownSource: """
                            * アスタリスクで始まるアイテム
                            * 2番目のアイテム
                            """
                        )

                        MarkdownPreviewCard(
                            title: "プラス (+)",
                            markdownSource: """
                            + プラスで始まるアイテム
                            + 2番目のアイテム
                            """
                        )
                    }
                }

                // Nested list
                CatalogSectionCard(title: "ネストしたリスト") {
                    MarkdownPreviewCard(
                        title: "階層構造",
                        description: "インデントでサブリストを作成",
                        markdownSource: """
                        - 親アイテム1
                          - 子アイテム1-1
                          - 子アイテム1-2
                            - 孫アイテム1-2-1
                        - 親アイテム2
                          - 子アイテム2-1
                        """
                    )
                }

                // With inline elements
                CatalogSectionCard(title: "インライン要素を含むリスト") {
                    MarkdownPreviewCard(
                        title: "装飾付きアイテム",
                        markdownSource: """
                        - **太字のアイテム**
                        - *斜体のアイテム*
                        - `コード`を含むアイテム
                        - [リンク](https://example.com)を含むアイテム
                        """
                    )
                }

                // Usage
                CatalogSectionCard(title: "使用例") {
                    CodeSnippetView(
                        code: """
                        MarkdownView(\"\"\"
                        - 最初のアイテム
                        - 2番目のアイテム
                          - ネストしたアイテム
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
        UnorderedListCatalogView()
            .navigationTitle("順序なしリスト")
    }
    .theme(ThemeProvider())
}
