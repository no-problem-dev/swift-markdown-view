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
                    Text("SyntaxHighlighterプロトコルを使用してコードブロックの構文ハイライトを制御できます。デフォルトではハイライトなし（PlainTextHighlighter）で、SwiftMarkdownViewHighlightJSモジュールを使用することで50+言語のシンタックスハイライトが有効になります。")
                        .typography(.bodyMedium)
                        .foregroundStyle(colorPalette.onSurfaceVariant)
                }

                // Quick Start
                quickStartSection

                // Protocol definition
                protocolSection

                // Multi-language examples
                languageExamplesSection

                // Theme options
                themeSection

                // Integration
                integrationSection

                // Performance considerations
                performanceSection
            }
            .padding(spacing.lg)
        }
        .background(colorPalette.background)
    }

    // MARK: - Quick Start

    private var quickStartSection: some View {
        CatalogSectionCard(title: "クイックスタート") {
            VStack(alignment: .leading, spacing: spacing.md) {
                Text("シンタックスハイライトを有効にするには:")
                    .typography(.bodyMedium)
                    .foregroundStyle(colorPalette.onSurfaceVariant)

                CodeSnippetView(
                    code: """
                    import SwiftMarkdownViewHighlightJS

                    struct ContentView: View {
                        var body: some View {
                            MarkdownView(source)
                                .adaptiveSyntaxHighlighting()
                        }
                    }
                    """,
                    language: "swift"
                )

                HStack(spacing: spacing.sm) {
                    Image(systemName: "lightbulb.fill")
                        .foregroundStyle(colorPalette.primary)
                    Text("adaptiveSyntaxHighlighting()はライト/ダークモードを自動検出します")
                        .typography(.bodySmall)
                        .foregroundStyle(colorPalette.onSurfaceVariant)
                }
            }
        }
    }

    // MARK: - Protocol Section

    private var protocolSection: some View {
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
                        ) async throws -> AttributedString
                    }
                    """,
                    language: "swift"
                )

                Text("組み込み実装:")
                    .typography(.labelMedium)
                    .foregroundStyle(colorPalette.onSurface)
                    .padding(.top, spacing.sm)

                VStack(alignment: .leading, spacing: spacing.xs) {
                    highlighterRow(
                        "PlainTextHighlighter",
                        description: "デフォルト。色付けなし。",
                        isDefault: true
                    )
                    highlighterRow(
                        "HighlightJSSyntaxHighlighter",
                        description: "50+言語対応。SwiftMarkdownViewHighlightJSモジュール。",
                        isDefault: false
                    )
                }
            }
        }
    }

    // MARK: - Language Examples Section

    private var languageExamplesSection: some View {
        CatalogSectionCard(title: "言語別コード例") {
            VStack(alignment: .leading, spacing: spacing.lg) {
                Text("HighlightJSSyntaxHighlighterは50以上の言語をサポート:")
                    .typography(.bodyMedium)
                    .foregroundStyle(colorPalette.onSurfaceVariant)

                // Swift
                languageExample(
                    language: "swift",
                    title: "Swift",
                    code: """
                    struct ContentView: View {
                        @State private var count = 0

                        var body: some View {
                            VStack {
                                Text("Count: \\(count)")
                                    .font(.largeTitle)
                                Button("Increment") {
                                    count += 1
                                }
                            }
                        }
                    }
                    """
                )

                // TypeScript
                languageExample(
                    language: "typescript",
                    title: "TypeScript",
                    code: """
                    interface User {
                        id: number;
                        name: string;
                        email: string;
                    }

                    async function fetchUser(id: number): Promise<User> {
                        const response = await fetch(`/api/users/${id}`);
                        if (!response.ok) {
                            throw new Error('User not found');
                        }
                        return response.json();
                    }
                    """
                )

                // Python
                languageExample(
                    language: "python",
                    title: "Python",
                    code: """
                    from dataclasses import dataclass
                    from typing import List, Optional

                    @dataclass
                    class Task:
                        title: str
                        completed: bool = False
                        priority: Optional[int] = None

                    def filter_tasks(tasks: List[Task], completed: bool) -> List[Task]:
                        \"\"\"Filter tasks by completion status.\"\"\"
                        return [t for t in tasks if t.completed == completed]
                    """
                )

                // Go
                languageExample(
                    language: "go",
                    title: "Go",
                    code: """
                    package main

                    import (
                        "fmt"
                        "net/http"
                    )

                    func handler(w http.ResponseWriter, r *http.Request) {
                        fmt.Fprintf(w, "Hello, %s!", r.URL.Path[1:])
                    }

                    func main() {
                        http.HandleFunc("/", handler)
                        http.ListenAndServe(":8080", nil)
                    }
                    """
                )

                // Rust
                languageExample(
                    language: "rust",
                    title: "Rust",
                    code: """
                    use std::collections::HashMap;

                    fn main() {
                        let mut scores: HashMap<&str, i32> = HashMap::new();
                        scores.insert("Blue", 10);
                        scores.insert("Red", 50);

                        for (team, score) in &scores {
                            println!("{}: {}", team, score);
                        }
                    }
                    """
                )

                // Kotlin
                languageExample(
                    language: "kotlin",
                    title: "Kotlin",
                    code: """
                    data class User(
                        val id: Int,
                        val name: String,
                        val email: String
                    )

                    fun List<User>.filterByName(query: String): List<User> =
                        filter { it.name.contains(query, ignoreCase = true) }

                    suspend fun fetchUsers(): Result<List<User>> = runCatching {
                        api.getUsers()
                    }
                    """
                )

                // JSON
                languageExample(
                    language: "json",
                    title: "JSON",
                    code: """
                    {
                        "name": "swift-markdown-view",
                        "version": "1.0.0",
                        "dependencies": {
                            "swift-design-system": "^1.0.0",
                            "swift-markdown": "main"
                        },
                        "features": ["syntax-highlighting", "mermaid", "tables"]
                    }
                    """
                )

                // SQL
                languageExample(
                    language: "sql",
                    title: "SQL",
                    code: """
                    SELECT
                        u.id,
                        u.name,
                        COUNT(o.id) AS order_count
                    FROM users u
                    LEFT JOIN orders o ON u.id = o.user_id
                    WHERE u.created_at >= '2024-01-01'
                    GROUP BY u.id, u.name
                    HAVING COUNT(o.id) > 5
                    ORDER BY order_count DESC;
                    """
                )
            }
        }
    }

    // MARK: - Theme Section

    private var themeSection: some View {
        CatalogSectionCard(title: "テーマオプション") {
            VStack(alignment: .leading, spacing: spacing.md) {
                Text("HighlightJSSyntaxHighlighterには複数のテーマが用意されています:")
                    .typography(.bodyMedium)
                    .foregroundStyle(colorPalette.onSurfaceVariant)

                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: spacing.sm) {
                    themeChip("xcode", description: "Xcode標準")
                    themeChip("github", description: "GitHub風")
                    themeChip("atomOne", description: "Atom One")
                    themeChip("solarized", description: "Solarized")
                    themeChip("tokyoNight", description: "Tokyo Night")
                    themeChip("a11y", description: "アクセシビリティ推奨")
                }

                Text("テーマ指定例:")
                    .typography(.labelMedium)
                    .foregroundStyle(colorPalette.onSurface)
                    .padding(.top, spacing.sm)

                CodeSnippetView(
                    code: """
                    // 特定のテーマを使用
                    MarkdownView(source)
                        .adaptiveSyntaxHighlighting(theme: .github)

                    // 手動でカラーモード指定
                    MarkdownView(source)
                        .syntaxHighlighter(
                            HighlightJSSyntaxHighlighter(
                                theme: .atomOne,
                                colorMode: .dark
                            )
                        )
                    """,
                    language: "swift"
                )
            }
        }
    }

    // MARK: - Integration Section

    private var integrationSection: some View {
        CatalogSectionCard(title: "統合パターン") {
            VStack(alignment: .leading, spacing: spacing.lg) {
                Text("アプリ全体での一括設定:")
                    .typography(.labelMedium)
                    .foregroundStyle(colorPalette.onSurface)

                CodeSnippetView(
                    code: """
                    import SwiftMarkdownViewHighlightJS

                    @main
                    struct MyApp: App {
                        var body: some Scene {
                            WindowGroup {
                                ContentView()
                                    .theme(ThemeProvider())
                                    .adaptiveSyntaxHighlighting()
                            }
                        }
                    }
                    """,
                    language: "swift"
                )

                Text("カタログでの使用例:")
                    .typography(.labelMedium)
                    .foregroundStyle(colorPalette.onSurface)

                CodeSnippetView(
                    code: """
                    import SwiftMarkdownViewHighlightJS

                    struct CatalogView: View {
                        var body: some View {
                            MarkdownCatalogView()
                                .theme(ThemeProvider())
                                .adaptiveSyntaxHighlighting()
                        }
                    }
                    """,
                    language: "swift"
                )

                Text("ハイライト無効化:")
                    .typography(.labelMedium)
                    .foregroundStyle(colorPalette.onSurface)

                CodeSnippetView(
                    code: """
                    // デフォルトでハイライトなし
                    MarkdownView(source)

                    // 明示的にプレーンテキスト指定
                    MarkdownView(source)
                        .syntaxHighlighter(PlainTextHighlighter())
                    """,
                    language: "swift"
                )
            }
        }
    }

    // MARK: - Performance Section

    private var performanceSection: some View {
        CatalogSectionCard(title: "パフォーマンス") {
            VStack(alignment: .leading, spacing: spacing.sm) {
                performanceRow(
                    icon: "bolt.fill",
                    title: "非同期処理",
                    description: "ハイライト処理はasync/awaitでバックグラウンド実行されます"
                )

                performanceRow(
                    icon: "arrow.triangle.2.circlepath",
                    title: "自動フォールバック",
                    description: "エラー時はプレーンテキストにフォールバックします"
                )

                performanceRow(
                    icon: "leaf.fill",
                    title: "軽量デフォルト",
                    description: "PlainTextHighlighterは追加の依存関係なしで動作します"
                )

                performanceRow(
                    icon: "globe",
                    title: "言語自動検出",
                    description: "言語指定なしでも自動的に言語を推測します"
                )
            }
        }
    }

    // MARK: - Helper Views

    @ViewBuilder
    private func languageExample(language: String, title: String, code: String) -> some View {
        VStack(alignment: .leading, spacing: spacing.sm) {
            HStack {
                Text(title)
                    .typography(.labelMedium)
                    .foregroundStyle(colorPalette.onSurface)

                Text(language)
                    .typography(.labelSmall)
                    .fontDesign(.monospaced)
                    .padding(.horizontal, spacing.sm)
                    .padding(.vertical, spacing.xs)
                    .background(colorPalette.primaryContainer)
                    .foregroundStyle(colorPalette.onPrimaryContainer)
                    .clipShape(Capsule())
            }

            CodeSnippetView(code: code, language: language)
        }
    }

    @ViewBuilder
    private func highlighterRow(_ name: String, description: String, isDefault: Bool) -> some View {
        HStack(spacing: spacing.sm) {
            if isDefault {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(colorPalette.primary)
            } else {
                Image(systemName: "circle")
                    .foregroundStyle(colorPalette.onSurfaceVariant)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .typography(.labelMedium)
                    .foregroundStyle(colorPalette.onSurface)
                    .fontDesign(.monospaced)
                Text(description)
                    .typography(.bodySmall)
                    .foregroundStyle(colorPalette.onSurfaceVariant)
            }
        }
        .padding(.vertical, spacing.xs)
    }

    @ViewBuilder
    private func themeChip(_ theme: String, description: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(".\(theme)")
                .typography(.labelSmall)
                .fontDesign(.monospaced)
                .foregroundStyle(colorPalette.onSurface)
            Text(description)
                .typography(.bodySmall)
                .foregroundStyle(colorPalette.onSurfaceVariant)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(spacing.sm)
        .background(colorPalette.surfaceVariant)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    @ViewBuilder
    private func performanceRow(icon: String, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: spacing.sm) {
            Image(systemName: icon)
                .foregroundStyle(colorPalette.primary)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .typography(.labelMedium)
                    .foregroundStyle(colorPalette.onSurface)
                Text(description)
                    .typography(.bodySmall)
                    .foregroundStyle(colorPalette.onSurfaceVariant)
            }
        }
        .padding(.vertical, spacing.xs)
    }
}

#Preview {
    NavigationStack {
        SyntaxHighlighterCatalogView()
            .navigationTitle("シンタックスハイライター")
    }
    .theme(ThemeProvider())
}
