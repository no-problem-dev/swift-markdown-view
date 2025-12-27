import SwiftUI
import DesignSystem

/// Catalog view for HeadingStyle configuration.
public struct HeadingStyleCatalogView: View {

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
                    subtitle: "見出しの表示スタイルを制御します"
                ) {
                    Text("HeadingStyleプロトコルを使用して、各レベルの見出しのタイポグラフィ、色、余白、区切り線などをカスタマイズできます。")
                        .typography(.bodyMedium)
                        .foregroundStyle(colorPalette.onSurfaceVariant)
                }

                // Heading preview
                CatalogSectionCard(title: "見出しプレビュー") {
                    VStack(alignment: .leading, spacing: spacing.lg) {
                        Text("現在のスタイルでのレンダリング:")
                            .typography(.bodyMedium)
                            .foregroundStyle(colorPalette.onSurfaceVariant)

                        MarkdownView(sampleHeadings)
                            .padding(spacing.md)
                            .background(colorPalette.surfaceVariant.opacity(0.3))
                            .clipShape(RoundedRectangle(cornerRadius: radius.md))
                    }
                }

                // Built-in styles
                CatalogSectionCard(title: "組み込みスタイル") {
                    VStack(alignment: .leading, spacing: spacing.lg) {
                        styleDescription(
                            "DefaultHeadingStyle",
                            description: "標準的な見出しスタイル。レベルごとに適切なタイポグラフィを適用"
                        )

                        styleDescription(
                            "CompactHeadingStyle",
                            description: "余白を最小限に抑えたコンパクトなスタイル"
                        )

                        styleDescription(
                            "ColoredHeadingStyle",
                            description: "レベルごとに異なる色を適用するカラフルなスタイル"
                        )

                        styleDescription(
                            "DividedHeadingStyle",
                            description: "見出しの下に区切り線を表示するスタイル"
                        )
                    }
                }

                // Protocol definition
                CatalogSectionCard(title: "HeadingStyleプロトコル") {
                    VStack(alignment: .leading, spacing: spacing.md) {
                        Text("カスタムスタイルを作成するためのプロトコル定義:")
                            .typography(.bodyMedium)
                            .foregroundStyle(colorPalette.onSurfaceVariant)

                        CodeSnippetView(
                            code: """
                            public protocol HeadingStyle: Sendable {
                                func typography(for level: Int) -> Typography
                                func color(
                                    for level: Int,
                                    palette: ColorPalette
                                ) -> Color
                                func padding(for level: Int) -> EdgeInsets
                                func showDivider(for level: Int) -> Bool
                            }
                            """,
                            language: "swift"
                        )
                    }
                }

                // Heading levels
                CatalogSectionCard(title: "見出しレベル") {
                    VStack(alignment: .leading, spacing: spacing.sm) {
                        levelRow(1, syntax: "# H1", description: "最上位の見出し")
                        levelRow(2, syntax: "## H2", description: "セクション見出し")
                        levelRow(3, syntax: "### H3", description: "サブセクション")
                        levelRow(4, syntax: "#### H4", description: "小見出し")
                        levelRow(5, syntax: "##### H5", description: "詳細見出し")
                        levelRow(6, syntax: "###### H6", description: "最小の見出し")
                    }
                }

                // Custom style example
                CatalogSectionCard(title: "カスタムスタイル例") {
                    CodeSnippetView(
                        code: """
                        struct GradientHeadingStyle: HeadingStyle {
                            func typography(for level: Int) -> Typography {
                                switch level {
                                case 1: return .displayLarge
                                case 2: return .displayMedium
                                case 3: return .headlineLarge
                                default: return .headlineMedium
                                }
                            }

                            func color(
                                for level: Int,
                                palette: ColorPalette
                            ) -> Color {
                                // グラデーション効果
                                let hue = Double(level) * 0.1
                                return Color(hue: hue, saturation: 0.7, brightness: 0.8)
                            }

                            func padding(for level: Int) -> EdgeInsets {
                                EdgeInsets(
                                    top: CGFloat(24 - level * 2),
                                    leading: 0,
                                    bottom: CGFloat(12 - level),
                                    trailing: 0
                                )
                            }

                            func showDivider(for level: Int) -> Bool {
                                level <= 2
                            }
                        }
                        """,
                        language: "swift"
                    )
                }

                // Usage
                CatalogSectionCard(title: "使用例") {
                    CodeSnippetView(
                        code: """
                        // View Modifierで適用
                        MarkdownView(source)
                            .markdownHeadingStyle(DividedHeadingStyle())

                        // 環境値として設定
                        ContentView()
                            .environment(
                                \\.headingStyle,
                                ColoredHeadingStyle()
                            )
                        """,
                        language: "swift"
                    )
                }
            }
            .padding(spacing.lg)
        }
        .background(colorPalette.background)
    }

    private var sampleHeadings: String {
        """
        # 見出し1
        ## 見出し2
        ### 見出し3
        #### 見出し4
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
    private func levelRow(_ level: Int, syntax: String, description: String) -> some View {
        HStack {
            Text("H\(level)")
                .typography(.labelMedium)
                .foregroundStyle(colorPalette.primary)
                .frame(width: 30, alignment: .leading)

            Text(syntax)
                .typography(.bodySmall)
                .fontDesign(.monospaced)
                .foregroundStyle(colorPalette.onSurface)
                .frame(width: 80, alignment: .leading)

            Text(description)
                .typography(.bodySmall)
                .foregroundStyle(colorPalette.onSurfaceVariant)
        }
        .padding(.vertical, spacing.xs)
    }
}

#Preview {
    NavigationStack {
        HeadingStyleCatalogView()
            .navigationTitle("見出しスタイル")
    }
    .theme(ThemeProvider())
}
