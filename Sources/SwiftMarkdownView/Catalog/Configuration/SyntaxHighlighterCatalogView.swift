import SwiftUI
import DesignSystem

/// Catalog view for SyntaxHighlighter configuration.
public struct SyntaxHighlighterCatalogView: View {

    @Environment(\.colorPalette) private var colorPalette
    @Environment(\.spacingScale) private var spacing

    public init() {}

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: spacing.xl) {
                // Overview
                CatalogSectionCard(
                    title: "概要",
                    subtitle: "コードのシンタックスハイライトをカスタマイズします"
                ) {
                    Text("SyntaxHighlighterプロトコルに準拠したハイライターを作成することで、コードブロックの構文ハイライトを完全にカスタマイズできます。トークンの色、スタイルなどを制御できます。")
                        .typography(.bodyMedium)
                        .foregroundStyle(colorPalette.onSurfaceVariant)
                }

                // Protocol definition
                CatalogSectionCard(title: "SyntaxHighlighterプロトコル") {
                    VStack(alignment: .leading, spacing: spacing.md) {
                        Text("カスタムハイライターを作成するためのプロトコル定義:")
                            .typography(.bodyMedium)
                            .foregroundStyle(colorPalette.onSurfaceVariant)

                        CodeSnippetView(
                            code: """
                            public protocol SyntaxHighlighter: Sendable {
                                func highlight(
                                    _ code: String,
                                    language: String?
                                ) -> AttributedString
                            }
                            """,
                            language: "swift"
                        )
                    }
                }

                // Supported languages
                CatalogSectionCard(title: "サポート言語") {
                    VStack(alignment: .leading, spacing: spacing.md) {
                        Text("言語識別子を使用してハイライトを適用します:")
                            .typography(.bodyMedium)
                            .foregroundStyle(colorPalette.onSurfaceVariant)

                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: spacing.sm) {
                            languageChip("swift")
                            languageChip("python")
                            languageChip("javascript")
                            languageChip("typescript")
                            languageChip("java")
                            languageChip("kotlin")
                            languageChip("go")
                            languageChip("rust")
                            languageChip("c")
                            languageChip("cpp")
                            languageChip("html")
                            languageChip("css")
                        }
                    }
                }

                // Token types
                CatalogSectionCard(title: "トークンタイプ") {
                    VStack(alignment: .leading, spacing: spacing.sm) {
                        tokenRow("keyword", example: "let, func, class", color: colorPalette.primary)
                        tokenRow("string", example: "\"Hello\"", color: colorPalette.error)
                        tokenRow("number", example: "42, 3.14", color: colorPalette.tertiary)
                        tokenRow("comment", example: "// comment", color: colorPalette.onSurfaceVariant)
                        tokenRow("type", example: "String, Int", color: colorPalette.secondary)
                        tokenRow("function", example: "print()", color: colorPalette.tertiary)
                        tokenRow("variable", example: "myVar", color: colorPalette.onSurface)
                        tokenRow("operator", example: "+, -, =", color: colorPalette.onSurfaceVariant)
                    }
                }

                // Example implementations
                CatalogSectionCard(title: "実装例") {
                    VStack(alignment: .leading, spacing: spacing.lg) {
                        Text("シンプルなハイライター:")
                            .typography(.labelMedium)
                            .foregroundStyle(colorPalette.onSurfaceVariant)

                        CodeSnippetView(
                            code: """
                            struct SimpleHighlighter: SyntaxHighlighter {
                                func highlight(
                                    _ code: String,
                                    language: String?
                                ) -> AttributedString {
                                    var result = AttributedString(code)

                                    // キーワードを太字に
                                    let keywords = ["let", "var", "func", "class"]
                                    for keyword in keywords {
                                        // キーワードの位置を検索して属性を適用
                                        // ...
                                    }

                                    return result
                                }
                            }
                            """,
                            language: "swift"
                        )

                        Text("テーマ対応ハイライター:")
                            .typography(.labelMedium)
                            .foregroundStyle(colorPalette.onSurfaceVariant)

                        CodeSnippetView(
                            code: """
                            struct ThemedHighlighter: SyntaxHighlighter {
                                let colorScheme: ColorScheme

                                var keywordColor: Color {
                                    colorScheme == .dark
                                        ? .pink
                                        : .purple
                                }

                                var stringColor: Color {
                                    colorScheme == .dark
                                        ? .orange
                                        : .red
                                }

                                func highlight(
                                    _ code: String,
                                    language: String?
                                ) -> AttributedString {
                                    // テーマに応じた色でハイライト
                                    // ...
                                }
                            }
                            """,
                            language: "swift"
                        )
                    }
                }

                // Integration with rendering options
                CatalogSectionCard(title: "レンダリングオプションとの連携") {
                    VStack(alignment: .leading, spacing: spacing.md) {
                        Text("MarkdownRenderingOptionsでシンタックスハイライトを有効/無効にできます:")
                            .typography(.bodyMedium)
                            .foregroundStyle(colorPalette.onSurfaceVariant)

                        CodeSnippetView(
                            code: """
                            // ハイライトを無効化
                            MarkdownView(source)
                                .markdownRenderingOptions(
                                    .init(enableSyntaxHighlighting: false)
                                )

                            // カスタムハイライターを使用
                            MarkdownView(source)
                                .markdownSyntaxHighlighter(MyHighlighter())
                            """,
                            language: "swift"
                        )
                    }
                }

                // Usage
                CatalogSectionCard(title: "使用例") {
                    CodeSnippetView(
                        code: """
                        // View Modifierで適用
                        MarkdownView(source)
                            .markdownSyntaxHighlighter(SimpleHighlighter())

                        // 環境値として設定
                        ContentView()
                            .environment(
                                \\.syntaxHighlighter,
                                ThemedHighlighter(colorScheme: .dark)
                            )
                        """,
                        language: "swift"
                    )
                }

                // Performance considerations
                CatalogSectionCard(title: "パフォーマンス考慮事項") {
                    VStack(alignment: .leading, spacing: spacing.sm) {
                        performanceRow(
                            "キャッシング",
                            description: "同じコードのハイライト結果をキャッシュすることで、再計算を避けられます"
                        )

                        performanceRow(
                            "遅延処理",
                            description: "大きなコードブロックは表示時に遅延ハイライトすることを検討してください"
                        )

                        performanceRow(
                            "軽量な実装",
                            description: "複雑な正規表現よりもシンプルなトークン化を優先してください"
                        )
                    }
                }
            }
            .padding(spacing.lg)
        }
        .background(colorPalette.background)
    }

    @ViewBuilder
    private func languageChip(_ language: String) -> some View {
        Text(language)
            .typography(.labelSmall)
            .fontDesign(.monospaced)
            .padding(.horizontal, spacing.sm)
            .padding(.vertical, spacing.xs)
            .background(colorPalette.primaryContainer)
            .foregroundStyle(colorPalette.onPrimaryContainer)
            .clipShape(Capsule())
    }

    @ViewBuilder
    private func tokenRow(_ name: String, example: String, color: Color) -> some View {
        HStack {
            Circle()
                .fill(color)
                .frame(width: 12, height: 12)

            Text(name)
                .typography(.labelMedium)
                .foregroundStyle(colorPalette.onSurface)
                .frame(width: 80, alignment: .leading)

            Text(example)
                .typography(.bodySmall)
                .fontDesign(.monospaced)
                .foregroundStyle(color)
        }
        .padding(.vertical, spacing.xs)
    }

    @ViewBuilder
    private func performanceRow(_ title: String, description: String) -> some View {
        VStack(alignment: .leading, spacing: spacing.xs) {
            HStack(spacing: spacing.sm) {
                Image(systemName: "bolt.fill")
                    .foregroundStyle(colorPalette.primary)
                    .typography(.labelSmall)

                Text(title)
                    .typography(.labelMedium)
                    .foregroundStyle(colorPalette.onSurface)
            }

            Text(description)
                .typography(.bodySmall)
                .foregroundStyle(colorPalette.onSurfaceVariant)
                .padding(.leading, spacing.lg)
        }
    }
}

#Preview {
    NavigationStack {
        SyntaxHighlighterCatalogView()
            .navigationTitle("シンタックスハイライター")
    }
    .theme(ThemeProvider())
}
