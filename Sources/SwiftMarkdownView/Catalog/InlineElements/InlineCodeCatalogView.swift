import SwiftUI
import DesignSystem

/// Catalog view for inline code elements.
public struct InlineCodeCatalogView: View {

    @Environment(\.colorPalette) private var colorPalette
    @Environment(\.spacingScale) private var spacing

    public init() {}

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: spacing.xl) {
                // Overview
                CatalogSectionCard(
                    title: "概要",
                    subtitle: "文中にコードスニペットを埋め込みます"
                ) {
                    Text("バッククォート(`)でテキストを囲むと、インラインコードとして表示されます。変数名、関数名、コマンドなどを本文中に示すのに適しています。")
                        .typography(.bodyMedium)
                        .foregroundStyle(colorPalette.onSurfaceVariant)
                }

                // Basic usage
                CatalogSectionCard(title: "基本的な使い方") {
                    VStack(alignment: .leading, spacing: spacing.lg) {
                        MarkdownPreviewCard(
                            title: "変数名",
                            markdownSource: "`userName` 変数にユーザー名を格納します。"
                        )

                        MarkdownPreviewCard(
                            title: "関数名",
                            markdownSource: "`fetchData()` 関数を呼び出してデータを取得します。"
                        )

                        MarkdownPreviewCard(
                            title: "コマンド",
                            markdownSource: "ターミナルで `npm install` を実行してください。"
                        )
                    }
                }

                // In sentences
                CatalogSectionCard(title: "文中での使用") {
                    MarkdownPreviewCard(
                        title: "技術ドキュメントの例",
                        markdownSource: """
                        `ContentView` 構造体は `View` プロトコルに準拠しています。
                        `body` プロパティで `some View` を返す必要があります。
                        """
                    )
                }

                // With backticks inside
                CatalogSectionCard(title: "バッククォートを含むコード") {
                    MarkdownPreviewCard(
                        title: "二重バッククォート",
                        description: "コード内にバッククォートがある場合",
                        markdownSource: "テンプレートリテラルは `` `Hello ${name}` `` のように書きます。"
                    )
                }

                // Difference from code block
                CatalogSectionCard(title: "コードブロックとの違い") {
                    VStack(alignment: .leading, spacing: spacing.md) {
                        Text("インラインコード vs コードブロック")
                            .typography(.labelMedium)
                            .foregroundStyle(colorPalette.onSurfaceVariant)

                        VStack(alignment: .leading, spacing: spacing.sm) {
                            differenceRow("インラインコード", description: "文中の短いコード")
                            differenceRow("コードブロック", description: "複数行のコード、シンタックスハイライト")
                        }
                    }
                }

                // Styling
                CatalogSectionCard(title: "スタイリング") {
                    VStack(alignment: .leading, spacing: spacing.md) {
                        Text("インラインコードは以下のスタイルが適用されます:")
                            .typography(.bodyMedium)
                            .foregroundStyle(colorPalette.onSurfaceVariant)

                        VStack(alignment: .leading, spacing: spacing.xs) {
                            Text("• 等幅フォント")
                            Text("• 背景色付き")
                            Text("• 角丸の境界")
                        }
                        .typography(.bodySmall)
                        .foregroundStyle(colorPalette.onSurfaceVariant)
                    }
                }

                // Usage
                CatalogSectionCard(title: "使用例") {
                    CodeSnippetView(
                        code: """
                        MarkdownView(\"\"\"
                        `print()` 関数で出力します。
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

    @ViewBuilder
    private func differenceRow(_ title: String, description: String) -> some View {
        HStack {
            Text(title)
                .typography(.bodyMedium)
                .foregroundStyle(colorPalette.onSurface)
                .frame(width: 120, alignment: .leading)

            Text(description)
                .typography(.bodySmall)
                .foregroundStyle(colorPalette.onSurfaceVariant)
        }
    }
}

#Preview {
    NavigationStack {
        InlineCodeCatalogView()
            .navigationTitle("インラインコード")
    }
    .theme(ThemeProvider())
}
