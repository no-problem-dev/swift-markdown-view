import SwiftUI
import DesignSystem

/// Catalog view for LinkStyle configuration.
public struct LinkStyleCatalogView: View {

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
                    subtitle: "リンクの表示スタイルを制御します"
                ) {
                    Text("LinkStyleプロトコルを使用して、リンクの色、下線、フォントウェイトなどをカスタマイズできます。アプリのデザインに合わせたリンクスタイルを適用できます。")
                        .typography(.bodyMedium)
                        .foregroundStyle(colorPalette.onSurfaceVariant)
                }

                // Link preview
                CatalogSectionCard(title: "リンクプレビュー") {
                    VStack(alignment: .leading, spacing: spacing.lg) {
                        Text("現在のスタイルでのレンダリング:")
                            .typography(.bodyMedium)
                            .foregroundStyle(colorPalette.onSurfaceVariant)

                        MarkdownView(sampleLinks)
                            .padding(spacing.md)
                            .background(colorPalette.surfaceVariant.opacity(0.3))
                            .clipShape(RoundedRectangle(cornerRadius: radius.md))
                    }
                }

                // Built-in styles
                CatalogSectionCard(title: "組み込みスタイル") {
                    VStack(alignment: .leading, spacing: spacing.lg) {
                        styleDescription(
                            "DefaultLinkStyle",
                            description: "プライマリカラー、下線なし、標準ウェイト"
                        )

                        styleDescription(
                            "SubtleLinkStyle",
                            description: "控えめな色、下線なし、ミニマルな見た目"
                        )

                        styleDescription(
                            "BoldLinkStyle",
                            description: "太字、下線なし、強調されたリンク"
                        )

                        styleDescription(
                            "ClassicLinkStyle",
                            description: "青色、下線あり、伝統的なWebリンクスタイル"
                        )

                        styleDescription(
                            "MonochromeLinkStyle",
                            description: "モノクロ、下線あり、テキストと同じ色"
                        )
                    }
                }

                // Protocol definition
                CatalogSectionCard(title: "LinkStyleプロトコル") {
                    VStack(alignment: .leading, spacing: spacing.md) {
                        Text("カスタムスタイルを作成するためのプロトコル定義:")
                            .typography(.bodyMedium)
                            .foregroundStyle(colorPalette.onSurfaceVariant)

                        CodeSnippetView(
                            code: """
                            public protocol LinkStyle: Sendable {
                                var underlineStyle: Text.LineStyle? { get }
                                func color(palette: ColorPalette) -> Color
                                var fontWeight: Font.Weight? { get }
                            }
                            """,
                            language: "swift"
                        )
                    }
                }

                // Link types
                CatalogSectionCard(title: "リンクの種類") {
                    VStack(alignment: .leading, spacing: spacing.lg) {
                        MarkdownPreviewCard(
                            title: "基本リンク",
                            markdownSource: "[Apple](https://www.apple.com)"
                        )

                        MarkdownPreviewCard(
                            title: "タイトル付きリンク",
                            markdownSource: "[Apple](https://www.apple.com \"Apple公式サイト\")"
                        )

                        MarkdownPreviewCard(
                            title: "インラインリンク",
                            markdownSource: "詳細は[こちら](https://example.com)をご覧ください。"
                        )
                    }
                }

                // Custom style example
                CatalogSectionCard(title: "カスタムスタイル例") {
                    CodeSnippetView(
                        code: """
                        struct GradientLinkStyle: LinkStyle {
                            let underlineStyle: Text.LineStyle? = .single

                            func color(palette: ColorPalette) -> Color {
                                // グラデーション効果は単色で代替
                                palette.tertiary
                            }

                            let fontWeight: Font.Weight? = .semibold
                        }

                        struct DashedLinkStyle: LinkStyle {
                            let underlineStyle: Text.LineStyle? = Text.LineStyle(
                                pattern: .dash,
                                color: .blue
                            )

                            func color(palette: ColorPalette) -> Color {
                                .blue
                            }

                            let fontWeight: Font.Weight? = nil
                        }
                        """,
                        language: "swift"
                    )
                }

                // Underline styles
                CatalogSectionCard(title: "下線スタイル") {
                    VStack(alignment: .leading, spacing: spacing.sm) {
                        underlineRow("なし", pattern: "nil")
                        underlineRow("実線", pattern: ".single")
                        underlineRow("破線", pattern: ".dash")
                        underlineRow("点線", pattern: ".dot")
                        underlineRow("ダッシュ＋ドット", pattern: ".dashDot")
                    }
                }

                // Usage
                CatalogSectionCard(title: "使用例") {
                    CodeSnippetView(
                        code: """
                        // View Modifierで適用
                        MarkdownView(source)
                            .markdownLinkStyle(ClassicLinkStyle())

                        // 環境値として設定
                        ContentView()
                            .environment(
                                \\.linkStyle,
                                SubtleLinkStyle()
                            )

                        // アプリ全体に適用
                        @main
                        struct MyApp: App {
                            var body: some Scene {
                                WindowGroup {
                                    ContentView()
                                        .markdownLinkStyle(BoldLinkStyle())
                                }
                            }
                        }
                        """,
                        language: "swift"
                    )
                }
            }
            .padding(spacing.lg)
        }
        .background(colorPalette.background)
    }

    private var sampleLinks: String {
        """
        このテキストには[リンク](https://example.com)が含まれています。

        複数の[リンク1](https://example.com)と[リンク2](https://example.org)もサポートしています。
        """
    }

    @ViewBuilder
    private func styleDescription(_ name: String, description: String) -> some View {
        VStack(alignment: .leading, spacing: spacing.xs) {
            Text(name)
                .typography(.labelMedium)
                .fontDesign(.monospaced)
                .foregroundStyle(colorPalette.primary)

            Text(description)
                .typography(.bodySmall)
                .foregroundStyle(colorPalette.onSurfaceVariant)
        }
        .padding(spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(colorPalette.surfaceVariant.opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: radius.md))
    }

    @ViewBuilder
    private func underlineRow(_ name: String, pattern: String) -> some View {
        HStack {
            Text(name)
                .typography(.bodyMedium)
                .foregroundStyle(colorPalette.onSurface)
                .frame(width: 120, alignment: .leading)

            Text(pattern)
                .typography(.bodySmall)
                .fontDesign(.monospaced)
                .foregroundStyle(colorPalette.onSurfaceVariant)
        }
        .padding(.vertical, spacing.xs)
    }
}

#Preview {
    NavigationStack {
        LinkStyleCatalogView()
            .navigationTitle("リンクスタイル")
    }
    .theme(ThemeProvider())
}
