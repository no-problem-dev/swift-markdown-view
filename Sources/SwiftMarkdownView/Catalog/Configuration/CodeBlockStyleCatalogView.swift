import SwiftUI
import DesignSystem

/// Catalog view for CodeBlockStyle configuration.
public struct CodeBlockStyleCatalogView: View {

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
                    subtitle: "コードブロックの表示スタイルを制御します"
                ) {
                    Text("CodeBlockStyleプロトコルを使用して、コードブロックの外観をカスタマイズできます。言語ラベル、行番号、コピーボタン、背景色などを制御できます。")
                        .typography(.bodyMedium)
                        .foregroundStyle(colorPalette.onSurfaceVariant)
                }

                // Code block preview
                CatalogSectionCard(title: "コードブロックプレビュー") {
                    VStack(alignment: .leading, spacing: spacing.lg) {
                        Text("現在のスタイルでのレンダリング:")
                            .typography(.bodyMedium)
                            .foregroundStyle(colorPalette.onSurfaceVariant)

                        MarkdownView(sampleCode)
                            .padding(spacing.md)
                            .background(colorPalette.surfaceVariant.opacity(0.3))
                            .clipShape(RoundedRectangle(cornerRadius: radius.md))
                    }
                }

                // Built-in styles
                CatalogSectionCard(title: "組み込みスタイル") {
                    VStack(alignment: .leading, spacing: spacing.lg) {
                        styleDescription(
                            "DefaultCodeBlockStyle",
                            features: ["言語ラベル表示", "行番号表示", "コピーボタン", "標準の背景色"]
                        )

                        styleDescription(
                            "MinimalCodeBlockStyle",
                            features: ["シンプルな外観", "ラベルなし", "行番号なし", "コピーボタンなし"]
                        )

                        styleDescription(
                            "TerminalCodeBlockStyle",
                            features: ["ダークテーマ", "ターミナル風の見た目", "プロンプト表示", "グリーンテキスト"]
                        )
                    }
                }

                // Protocol definition
                CatalogSectionCard(title: "CodeBlockStyleプロトコル") {
                    VStack(alignment: .leading, spacing: spacing.md) {
                        Text("カスタムスタイルを作成するためのプロトコル定義:")
                            .typography(.bodyMedium)
                            .foregroundStyle(colorPalette.onSurfaceVariant)

                        CodeSnippetView(
                            code: """
                            public protocol CodeBlockStyle: Sendable {
                                var showLanguageLabel: Bool { get }
                                var showLineNumbers: Bool { get }
                                var showCopyButton: Bool { get }
                                var backgroundColor: Color { get }
                                var textColor: Color { get }
                                var lineNumberColor: Color { get }
                            }
                            """,
                            language: "swift"
                        )
                    }
                }

                // Custom style example
                CatalogSectionCard(title: "カスタムスタイル例") {
                    CodeSnippetView(
                        code: """
                        struct MyCodeBlockStyle: CodeBlockStyle {
                            let showLanguageLabel = true
                            let showLineNumbers = true
                            let showCopyButton = true
                            let backgroundColor = Color.blue.opacity(0.1)
                            let textColor = Color.primary
                            let lineNumberColor = Color.secondary
                        }

                        MarkdownView(source)
                            .markdownCodeBlockStyle(MyCodeBlockStyle())
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
                            .markdownCodeBlockStyle(TerminalCodeBlockStyle())

                        // 環境値として設定
                        ContentView()
                            .environment(
                                \\.codeBlockStyle,
                                MinimalCodeBlockStyle()
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

    private var sampleCode: String {
        """
        ```swift
        struct Greeting {
            let message: String

            func display() {
                print(message)
            }
        }
        ```
        """
    }

    @ViewBuilder
    private func styleDescription(_ name: String, features: [String]) -> some View {
        VStack(alignment: .leading, spacing: spacing.sm) {
            Text(name)
                .typography(.labelMedium)
                .fontDesign(.monospaced)
                .foregroundStyle(colorPalette.primary)

            ForEach(features, id: \.self) { feature in
                HStack(spacing: spacing.sm) {
                    Image(systemName: "checkmark.circle.fill")
                        .typography(.labelSmall)
                        .foregroundStyle(colorPalette.primary)

                    Text(feature)
                        .typography(.bodySmall)
                        .foregroundStyle(colorPalette.onSurfaceVariant)
                }
            }
        }
        .padding(spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(colorPalette.surfaceVariant.opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: radius.md))
    }
}

#Preview {
    NavigationStack {
        CodeBlockStyleCatalogView()
            .navigationTitle("コードブロックスタイル")
    }
    .theme(ThemeProvider())
}
