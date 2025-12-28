import SwiftUI
import DesignSystem

/// Catalog view for code block elements.
public struct CodeBlockCatalogView: View {

    @Environment(\.colorPalette) private var colorPalette
    @Environment(\.spacingScale) private var spacing

    public init() {}

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: spacing.xl) {
                // Overview
                CatalogSectionCard(
                    title: "概要",
                    subtitle: "コードブロックはソースコードを表示するために使用します"
                ) {
                    Text("バッククォート3つ(```)で囲むとコードブロックになります。言語名を指定するとシンタックスハイライトが適用されます。")
                        .typography(.bodyMedium)
                        .foregroundStyle(colorPalette.onSurfaceVariant)
                }

                // Swift example
                CatalogSectionCard(title: "Swift") {
                    MarkdownPreviewCard(
                        title: "Swift コード",
                        markdownSource: """
                        ```swift
                        struct ContentView: View {
                            var body: some View {
                                Text("Hello, World!")
                            }
                        }
                        ```
                        """
                    )
                }

                // Multiple languages
                CatalogSectionCard(title: "その他の言語") {
                    VStack(alignment: .leading, spacing: spacing.lg) {
                        MarkdownPreviewCard(
                            title: "Python",
                            markdownSource: """
                            ```python
                            def greet(name):
                                return f"Hello, {name}!"

                            print(greet("World"))
                            ```
                            """
                        )

                        MarkdownPreviewCard(
                            title: "TypeScript",
                            markdownSource: """
                            ```typescript
                            interface User {
                                id: number;
                                name: string;
                            }

                            const user: User = { id: 1, name: "Alice" };
                            ```
                            """
                        )

                        MarkdownPreviewCard(
                            title: "JSON",
                            markdownSource: """
                            ```json
                            {
                                "name": "SwiftMarkdownView",
                                "version": "1.0.0",
                                "dependencies": []
                            }
                            ```
                            """
                        )
                    }
                }

                // Without language
                CatalogSectionCard(title: "言語指定なし") {
                    MarkdownPreviewCard(
                        title: "プレーンテキスト",
                        description: "言語を指定しない場合はハイライトなしで表示",
                        markdownSource: """
                        ```
                        これはプレーンテキストのコードブロックです。
                        シンタックスハイライトは適用されません。
                        ```
                        """
                    )
                }

                // Supported languages
                CatalogSectionCard(title: "対応言語") {
                    VStack(alignment: .leading, spacing: spacing.sm) {
                        languageRow("Swift", aliases: ["swift"])
                        languageRow("TypeScript", aliases: ["typescript", "ts", "tsx"])
                        languageRow("JavaScript", aliases: ["javascript", "js", "jsx"])
                        languageRow("Python", aliases: ["python", "py"])
                        languageRow("Go", aliases: ["go", "golang"])
                        languageRow("Rust", aliases: ["rust", "rs"])
                        languageRow("Shell", aliases: ["shell", "bash", "sh", "zsh"])
                        languageRow("SQL", aliases: ["sql"])
                        languageRow("JSON", aliases: ["json"])
                        languageRow("YAML", aliases: ["yaml", "yml"])
                    }
                }

                // Usage
                CatalogSectionCard(title: "使用例") {
                    CodeSnippetView(
                        code: """
                        MarkdownView(\"\"\"
                        ```swift
                        let greeting = "Hello"
                        ```
                        \"\"\")
                        .codeBlockStyle(TerminalCodeBlockStyle())
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
    private func languageRow(_ name: String, aliases: [String]) -> some View {
        HStack {
            Text(name)
                .typography(.bodyMedium)
                .foregroundStyle(colorPalette.onSurface)

            Spacer()

            Text(aliases.joined(separator: ", "))
                .typography(.bodySmall)
                .fontDesign(.monospaced)
                .foregroundStyle(colorPalette.onSurfaceVariant)
        }
        .padding(.vertical, spacing.xs)
    }
}

#Preview {
    NavigationStack {
        CodeBlockCatalogView()
            .navigationTitle("コードブロック")
    }
    .theme(ThemeProvider())
}
