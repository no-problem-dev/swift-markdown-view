import SwiftUI
import DesignSystem

/// Catalog view for image elements.
public struct ImageCatalogView: View {

    @Environment(\.colorPalette) private var colorPalette
    @Environment(\.spacingScale) private var spacing
    @Environment(\.radiusScale) private var radius

    public init() {}

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: spacing.xl) {
                // Overview
                CatalogSectionCard(
                    title: "概要",
                    subtitle: "画像をMarkdown内に埋め込みます"
                ) {
                    Text("`![代替テキスト](URL)` の形式で画像を埋め込めます。リモートURL（https://）とローカルファイル（file://）の両方をサポートしています。")
                        .typography(.bodyMedium)
                        .foregroundStyle(colorPalette.onSurfaceVariant)
                }

                // Syntax
                CatalogSectionCard(title: "基本構文") {
                    VStack(alignment: .leading, spacing: spacing.md) {
                        Text("画像の構文:")
                            .typography(.labelMedium)
                            .foregroundStyle(colorPalette.onSurfaceVariant)

                        Text("![代替テキスト](URL \"タイトル\")")
                            .typography(.bodyMedium)
                            .fontDesign(.monospaced)
                            .padding(spacing.md)
                            .background(colorPalette.surfaceVariant)
                            .clipShape(RoundedRectangle(cornerRadius: radius.md))

                        VStack(alignment: .leading, spacing: spacing.xs) {
                            syntaxElement("代替テキスト", description: "画像が読み込めない場合に表示（必須）")
                            syntaxElement("URL", description: "画像のURL（必須）")
                            syntaxElement("タイトル", description: "ホバー時のツールチップ（省略可）")
                        }
                    }
                }

                // Remote image
                CatalogSectionCard(title: "リモート画像") {
                    MarkdownPreviewCard(
                        title: "HTTPS URL",
                        description: "インターネット上の画像",
                        markdownSource: "![Sample Image](https://picsum.photos/400/200)"
                    )
                }

                // With title
                CatalogSectionCard(title: "タイトル付き") {
                    MarkdownPreviewCard(
                        title: "ツールチップ表示",
                        markdownSource: "![Beautiful Landscape](https://picsum.photos/400/200 \"美しい風景\")"
                    )
                }

                // Inline vs Block
                CatalogSectionCard(title: "インライン vs ブロック") {
                    VStack(alignment: .leading, spacing: spacing.lg) {
                        MarkdownPreviewCard(
                            title: "ブロックレベル",
                            description: "段落内に単独で配置",
                            markdownSource: """
                            段落の前のテキスト。

                            ![Image](https://picsum.photos/300/150)

                            段落の後のテキスト。
                            """
                        )

                        MarkdownPreviewCard(
                            title: "インライン",
                            description: "テキストと同じ行に配置",
                            markdownSource: "テキストの中に ![icon](https://picsum.photos/20/20) 小さなアイコン。"
                        )
                    }
                }

                // Image rendering options
                CatalogSectionCard(title: "レンダリングオプション") {
                    VStack(alignment: .leading, spacing: spacing.md) {
                        Text("画像サイズを制限する:")
                            .typography(.labelMedium)
                            .foregroundStyle(colorPalette.onSurfaceVariant)

                        CodeSnippetView(
                            code: """
                            MarkdownView(source)
                                .markdownRenderingOptions(
                                    .init(
                                        maxImageHeight: 300,
                                        maxImageWidth: 400
                                    )
                                )
                            """,
                            language: "swift"
                        )

                        Text("画像の表示を無効にする:")
                            .typography(.labelMedium)
                            .foregroundStyle(colorPalette.onSurfaceVariant)
                            .padding(.top, spacing.md)

                        CodeSnippetView(
                            code: """
                            MarkdownView(source)
                                .markdownRenderingOptions(
                                    .init(renderImages: false)
                                )
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
                        # 画像を含むドキュメント

                        ![スクリーンショット](https://example.com/image.png)

                        上の画像は機能のスクリーンショットです。
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
    private func syntaxElement(_ name: String, description: String) -> some View {
        HStack(alignment: .top) {
            Text(name)
                .typography(.labelMedium)
                .fontDesign(.monospaced)
                .foregroundStyle(colorPalette.primary)
                .frame(width: 100, alignment: .leading)

            Text(description)
                .typography(.bodySmall)
                .foregroundStyle(colorPalette.onSurfaceVariant)
        }
    }
}

#Preview {
    NavigationStack {
        ImageCatalogView()
            .navigationTitle("画像")
    }
    .theme(ThemeProvider())
}
