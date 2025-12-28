import SwiftUI
import DesignSystem

/// Catalog view for text style elements (bold, italic, strikethrough).
public struct TextStylesCatalogView: View {

    @Environment(\.colorPalette) private var colorPalette
    @Environment(\.spacingScale) private var spacing

    public init() {}

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: spacing.xl) {
                // Overview
                CatalogSectionCard(
                    title: "概要",
                    subtitle: "テキストに様々なスタイルを適用できます"
                ) {
                    Text("Markdownでは特殊な文字でテキストを囲むことで、太字、斜体、取り消し線などのスタイルを適用できます。")
                        .typography(.bodyMedium)
                        .foregroundStyle(colorPalette.onSurfaceVariant)
                }

                // Bold
                CatalogSectionCard(title: "太字 (Bold)") {
                    VStack(alignment: .leading, spacing: spacing.lg) {
                        MarkdownPreviewCard(
                            title: "アスタリスク2つ",
                            markdownSource: "これは**太字**のテキストです。"
                        )

                        MarkdownPreviewCard(
                            title: "アンダースコア2つ",
                            markdownSource: "これは__太字__のテキストです。"
                        )
                    }
                }

                // Italic
                CatalogSectionCard(title: "斜体 (Italic)") {
                    VStack(alignment: .leading, spacing: spacing.lg) {
                        MarkdownPreviewCard(
                            title: "アスタリスク1つ",
                            markdownSource: "これは*斜体*のテキストです。"
                        )

                        MarkdownPreviewCard(
                            title: "アンダースコア1つ",
                            markdownSource: "これは_斜体_のテキストです。"
                        )
                    }
                }

                // Bold + Italic
                CatalogSectionCard(title: "太字 + 斜体") {
                    MarkdownPreviewCard(
                        title: "組み合わせ",
                        markdownSource: "これは***太字かつ斜体***のテキストです。"
                    )
                }

                // Strikethrough
                CatalogSectionCard(title: "取り消し線 (Strikethrough)") {
                    MarkdownPreviewCard(
                        title: "チルダ2つ",
                        description: "GitHub Flavored Markdown拡張",
                        markdownSource: "これは~~取り消し線~~のテキストです。"
                    )
                }

                // Combined example
                CatalogSectionCard(title: "組み合わせ例") {
                    MarkdownPreviewCard(
                        title: "様々なスタイルの混在",
                        markdownSource: """
                        この文章には**太字**、*斜体*、~~取り消し線~~が含まれています。

                        ***重要な警告*** - この操作は~~元に戻せません~~取り消し可能です。
                        """
                    )
                }

                // Syntax reference
                CatalogSectionCard(title: "構文リファレンス") {
                    VStack(alignment: .leading, spacing: spacing.sm) {
                        syntaxRow("太字", syntax: "**text** または __text__")
                        syntaxRow("斜体", syntax: "*text* または _text_")
                        syntaxRow("太字+斜体", syntax: "***text*** または ___text___")
                        syntaxRow("取り消し線", syntax: "~~text~~")
                    }
                }

                // Usage
                CatalogSectionCard(title: "使用例") {
                    CodeSnippetView(
                        code: """
                        MarkdownView(\"\"\"
                        **太字**、*斜体*、~~取り消し線~~
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
    private func syntaxRow(_ name: String, syntax: String) -> some View {
        HStack {
            Text(name)
                .typography(.bodyMedium)
                .foregroundStyle(colorPalette.onSurface)
                .frame(width: 100, alignment: .leading)

            Text(syntax)
                .typography(.bodySmall)
                .fontDesign(.monospaced)
                .foregroundStyle(colorPalette.onSurfaceVariant)
        }
        .padding(.vertical, spacing.xs)
    }
}

#Preview {
    NavigationStack {
        TextStylesCatalogView()
            .navigationTitle("テキストスタイル")
    }
    .theme(ThemeProvider())
}
