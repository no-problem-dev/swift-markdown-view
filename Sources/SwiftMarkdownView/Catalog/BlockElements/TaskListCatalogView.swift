import SwiftUI
import DesignSystem

/// Catalog view for task list (checkbox) elements.
public struct TaskListCatalogView: View {

    @Environment(\.colorPalette) private var colorPalette
    @Environment(\.spacingScale) private var spacing

    public init() {}

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: spacing.xl) {
                // Overview
                CatalogSectionCard(
                    title: "概要",
                    subtitle: "タスクリストはチェックボックス付きのリストです"
                ) {
                    Text("`- [ ]` で未完了、`- [x]` で完了のタスクアイテムを作成できます。GitHub Flavored Markdownで導入された拡張構文です。")
                        .typography(.bodyMedium)
                        .foregroundStyle(colorPalette.onSurfaceVariant)
                }

                // Basic task list
                CatalogSectionCard(title: "基本的なタスクリスト") {
                    MarkdownPreviewCard(
                        title: "完了/未完了の混在",
                        markdownSource: """
                        - [x] 完了したタスク
                        - [x] これも完了
                        - [ ] 未完了のタスク
                        - [ ] これも未完了
                        """
                    )
                }

                // All completed
                CatalogSectionCard(title: "すべて完了") {
                    MarkdownPreviewCard(
                        title: "完了リスト",
                        markdownSource: """
                        - [x] 設計書の作成
                        - [x] コードレビュー
                        - [x] テストの実行
                        - [x] デプロイ
                        """
                    )
                }

                // All pending
                CatalogSectionCard(title: "すべて未完了") {
                    MarkdownPreviewCard(
                        title: "TODOリスト",
                        markdownSource: """
                        - [ ] ドキュメントの更新
                        - [ ] バグ修正
                        - [ ] パフォーマンス改善
                        - [ ] リリースノート作成
                        """
                    )
                }

                // Nested task list
                CatalogSectionCard(title: "ネストしたタスクリスト") {
                    MarkdownPreviewCard(
                        title: "階層構造のタスク",
                        markdownSource: """
                        - [x] 親タスク1
                          - [x] サブタスク1-1
                          - [ ] サブタスク1-2
                        - [ ] 親タスク2
                          - [ ] サブタスク2-1
                          - [ ] サブタスク2-2
                        """
                    )
                }

                // With inline elements
                CatalogSectionCard(title: "インライン要素を含むタスク") {
                    MarkdownPreviewCard(
                        title: "装飾付きタスク",
                        markdownSource: """
                        - [x] **重要**: ドキュメント更新
                        - [ ] `config.json` を編集
                        - [ ] [ガイド](https://example.com)を確認
                        """
                    )
                }

                // Usage
                CatalogSectionCard(title: "使用例") {
                    CodeSnippetView(
                        code: """
                        MarkdownView(\"\"\"
                        - [x] 完了したタスク
                        - [ ] 未完了のタスク
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
}

#Preview {
    NavigationStack {
        TaskListCatalogView()
            .navigationTitle("タスクリスト")
    }
    .theme(ThemeProvider())
}
