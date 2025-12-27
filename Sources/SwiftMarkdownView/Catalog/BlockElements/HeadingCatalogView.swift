import SwiftUI
import DesignSystem

/// Catalog view for heading elements (H1-H6).
public struct HeadingCatalogView: View {

    @Environment(\.colorPalette) private var colorPalette
    @Environment(\.spacingScale) private var spacing

    public init() {}

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: spacing.xl) {
                // Overview
                CatalogSectionCard(
                    title: "概要",
                    subtitle: "見出しは文書の構造を示すために使用します"
                ) {
                    Text("Markdownでは `#` の数で見出しレベルを指定します。H1が最も大きく、H6が最も小さい見出しです。")
                        .typography(.bodyMedium)
                        .foregroundStyle(colorPalette.onSurfaceVariant)
                }

                // All heading levels
                CatalogSectionCard(title: "見出しレベル") {
                    VStack(alignment: .leading, spacing: spacing.lg) {
                        ForEach(1...6, id: \.self) { level in
                            MarkdownPreviewCard(
                                title: "H\(level)",
                                description: headingDescription(for: level),
                                markdownSource: String(repeating: "#", count: level) + " 見出しレベル \(level)"
                            )
                        }
                    }
                }

                // Usage example
                CatalogSectionCard(title: "使用例") {
                    VStack(alignment: .leading, spacing: spacing.md) {
                        Text("SwiftUIでの使用方法")
                            .typography(.titleSmall)
                            .foregroundStyle(colorPalette.onSurface)

                        CodeSnippetView(
                            code: """
                            MarkdownView(\"\"\"
                            # メインタイトル
                            ## セクション見出し
                            ### サブセクション
                            \"\"\")
                            """,
                            language: "swift"
                        )

                        Text("カスタムスタイルの適用")
                            .typography(.titleSmall)
                            .foregroundStyle(colorPalette.onSurface)
                            .padding(.top, spacing.md)

                        CodeSnippetView(
                            code: """
                            MarkdownView(source)
                                .headingStyle(ColoredHeadingStyle())
                            """,
                            language: "swift"
                        )
                    }
                }
            }
            .padding(spacing.lg)
        }
        .background(colorPalette.background)
    }

    private func headingDescription(for level: Int) -> String {
        switch level {
        case 1: return "ページタイトルに使用"
        case 2: return "主要セクションに使用"
        case 3: return "サブセクションに使用"
        case 4: return "小見出しに使用"
        case 5: return "補足的な見出しに使用"
        case 6: return "最小の見出しに使用"
        default: return ""
        }
    }
}

#Preview {
    NavigationStack {
        HeadingCatalogView()
            .navigationTitle("見出し")
    }
    .theme(ThemeProvider())
}
