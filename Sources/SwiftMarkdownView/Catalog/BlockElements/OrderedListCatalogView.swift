import SwiftUI
import DesignSystem

/// Catalog view for ordered (numbered) list elements.
public struct OrderedListCatalogView: View {

    @Environment(\.colorPalette) private var colorPalette
    @Environment(\.spacingScale) private var spacing

    public init() {}

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: spacing.xl) {
                // Overview
                CatalogSectionCard(
                    title: "概要",
                    subtitle: "順序付きリストは手順や順番のある項目に使用します"
                ) {
                    Text("数字とピリオド(`1.`)で始まる行がリストアイテムになります。実際の番号に関係なく、自動的に連番が振られます。")
                        .typography(.bodyMedium)
                        .foregroundStyle(colorPalette.onSurfaceVariant)
                }

                // Basic list
                CatalogSectionCard(title: "基本的なリスト") {
                    MarkdownPreviewCard(
                        title: "連番リスト",
                        markdownSource: """
                        1. 最初のステップ
                        2. 2番目のステップ
                        3. 3番目のステップ
                        """
                    )
                }

                // Auto numbering
                CatalogSectionCard(title: "自動採番") {
                    MarkdownPreviewCard(
                        title: "すべて1.でも正しく採番される",
                        description: "実際の数字は関係なく連番になります",
                        markdownSource: """
                        1. 最初のアイテム
                        1. 2番目のアイテム
                        1. 3番目のアイテム
                        """
                    )
                }

                // Custom start number
                CatalogSectionCard(title: "開始番号の指定") {
                    MarkdownPreviewCard(
                        title: "5から開始",
                        markdownSource: """
                        5. 5番目から開始
                        6. 6番目のアイテム
                        7. 7番目のアイテム
                        """
                    )
                }

                // Nested list
                CatalogSectionCard(title: "ネストしたリスト") {
                    MarkdownPreviewCard(
                        title: "階層構造",
                        markdownSource: """
                        1. 親アイテム1
                           1. 子アイテム1-1
                           2. 子アイテム1-2
                        2. 親アイテム2
                           1. 子アイテム2-1
                        """
                    )
                }

                // Mixed with unordered
                CatalogSectionCard(title: "順序なしリストとの組み合わせ") {
                    MarkdownPreviewCard(
                        title: "混在リスト",
                        markdownSource: """
                        1. 最初のステップ
                           - サブ項目A
                           - サブ項目B
                        2. 2番目のステップ
                           - サブ項目C
                        """
                    )
                }

                // Usage
                CatalogSectionCard(title: "使用例") {
                    CodeSnippetView(
                        code: """
                        MarkdownView(\"\"\"
                        1. インストール
                        2. 設定
                        3. 実行
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
        OrderedListCatalogView()
            .navigationTitle("順序付きリスト")
    }
    .theme(ThemeProvider())
}
