import SwiftUI
import DesignSystem

/// Catalog view for line break elements.
public struct SoftBreakCatalogView: View {

    @Environment(\.colorPalette) private var colorPalette
    @Environment(\.spacingScale) private var spacing

    public init() {}

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: spacing.xl) {
                // Overview
                CatalogSectionCard(
                    title: "概要",
                    subtitle: "Markdownでの改行の扱い"
                ) {
                    Text("Markdownでは単純な改行（Enter）はソフト改行として扱われ、通常は空白に変換されます。ハード改行（強制改行）には特別な構文が必要です。")
                        .typography(.bodyMedium)
                        .foregroundStyle(colorPalette.onSurfaceVariant)
                }

                // Soft break
                CatalogSectionCard(title: "ソフト改行") {
                    VStack(alignment: .leading, spacing: spacing.lg) {
                        MarkdownPreviewCard(
                            title: "単純な改行は空白になる",
                            description: "ソースでは2行だが、表示では1行",
                            markdownSource: """
                            最初の行
                            2番目の行
                            """
                        )

                        Text("ソースコードでは改行されていますが、レンダリング時には空白として扱われ、連続したテキストになります。")
                            .typography(.bodySmall)
                            .foregroundStyle(colorPalette.onSurfaceVariant)
                    }
                }

                // Hard break
                CatalogSectionCard(title: "ハード改行（強制改行）") {
                    VStack(alignment: .leading, spacing: spacing.lg) {
                        MarkdownPreviewCard(
                            title: "行末に2つのスペース",
                            description: "行末に2つ以上のスペースを入れる",
                            markdownSource: "最初の行  \n2番目の行"
                        )

                        MarkdownPreviewCard(
                            title: "バックスラッシュ",
                            description: "行末にバックスラッシュを入れる",
                            markdownSource: "最初の行\\\n2番目の行"
                        )
                    }
                }

                // Paragraph break
                CatalogSectionCard(title: "段落分け") {
                    MarkdownPreviewCard(
                        title: "空行で段落を分ける",
                        description: "段落間には適切なスペースが入る",
                        markdownSource: """
                        最初の段落のテキスト。

                        2番目の段落のテキスト。
                        """
                    )
                }

                // Comparison
                CatalogSectionCard(title: "比較") {
                    VStack(alignment: .leading, spacing: spacing.sm) {
                        breakTypeRow("ソフト改行", syntax: "単純な改行", result: "空白に変換")
                        breakTypeRow("ハード改行", syntax: "行末に2スペース", result: "強制改行")
                        breakTypeRow("段落分け", syntax: "空行", result: "新しい段落")
                    }
                }

                // Usage
                CatalogSectionCard(title: "使用例") {
                    CodeSnippetView(
                        code: """
                        MarkdownView(\"\"\"
                        詩の1行目
                        詩の2行目
                        詩の3行目

                        新しい段落
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
    private func breakTypeRow(_ type: String, syntax: String, result: String) -> some View {
        HStack {
            Text(type)
                .typography(.bodyMedium)
                .foregroundStyle(colorPalette.onSurface)
                .frame(width: 100, alignment: .leading)

            Text(syntax)
                .typography(.bodySmall)
                .fontDesign(.monospaced)
                .foregroundStyle(colorPalette.onSurfaceVariant)
                .frame(width: 120, alignment: .leading)

            Text(result)
                .typography(.bodySmall)
                .foregroundStyle(colorPalette.onSurfaceVariant)
        }
        .padding(.vertical, spacing.xs)
    }
}

#Preview {
    NavigationStack {
        SoftBreakCatalogView()
            .navigationTitle("改行")
    }
    .theme(ThemeProvider())
}
