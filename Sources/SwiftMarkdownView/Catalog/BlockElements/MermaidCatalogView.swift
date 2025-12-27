import SwiftUI
import DesignSystem

/// Catalog view for Mermaid diagram elements.
public struct MermaidCatalogView: View {

    @Environment(\.colorPalette) private var colorPalette
    @Environment(\.spacingScale) private var spacing

    public init() {}

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: spacing.xl) {
                // Overview
                CatalogSectionCard(
                    title: "概要",
                    subtitle: "Mermaidはテキストベースのダイアグラム記法です"
                ) {
                    Text("コードブロックの言語に `mermaid` を指定すると、フローチャート、シーケンス図、クラス図などのダイアグラムを描画できます。")
                        .typography(.bodyMedium)
                        .foregroundStyle(colorPalette.onSurfaceVariant)
                }

                // Flowchart
                CatalogSectionCard(title: "フローチャート") {
                    MarkdownPreviewCard(
                        title: "基本的なフローチャート",
                        markdownSource: """
                        ```mermaid
                        graph TD
                            A[開始] --> B{条件}
                            B -->|Yes| C[処理1]
                            B -->|No| D[処理2]
                            C --> E[終了]
                            D --> E
                        ```
                        """
                    )
                }

                // Sequence diagram
                CatalogSectionCard(title: "シーケンス図") {
                    MarkdownPreviewCard(
                        title: "API呼び出しの流れ",
                        markdownSource: """
                        ```mermaid
                        sequenceDiagram
                            participant C as Client
                            participant S as Server
                            participant D as Database
                            C->>S: リクエスト
                            S->>D: クエリ
                            D-->>S: 結果
                            S-->>C: レスポンス
                        ```
                        """
                    )
                }

                // Class diagram
                CatalogSectionCard(title: "クラス図") {
                    MarkdownPreviewCard(
                        title: "クラス関係",
                        markdownSource: """
                        ```mermaid
                        classDiagram
                            class Animal {
                                +String name
                                +move()
                            }
                            class Dog {
                                +bark()
                            }
                            Animal <|-- Dog
                        ```
                        """
                    )
                }

                // State diagram
                CatalogSectionCard(title: "状態図") {
                    MarkdownPreviewCard(
                        title: "注文ステータス",
                        markdownSource: """
                        ```mermaid
                        stateDiagram-v2
                            [*] --> 注文受付
                            注文受付 --> 処理中
                            処理中 --> 発送済
                            発送済 --> 配達完了
                            配達完了 --> [*]
                        ```
                        """
                    )
                }

                // Pie chart
                CatalogSectionCard(title: "円グラフ") {
                    MarkdownPreviewCard(
                        title: "売上構成",
                        markdownSource: """
                        ```mermaid
                        pie title 売上構成
                            "製品A" : 40
                            "製品B" : 30
                            "製品C" : 20
                            "その他" : 10
                        ```
                        """
                    )
                }

                // Usage
                CatalogSectionCard(title: "使用例") {
                    VStack(alignment: .leading, spacing: spacing.md) {
                        CodeSnippetView(
                            code: """
                            MarkdownView(\"\"\"
                            ```mermaid
                            graph LR
                                A --> B
                            ```
                            \"\"\")
                            """,
                            language: "swift"
                        )

                        Text("Mermaidを無効にする場合:")
                            .typography(.labelMedium)
                            .foregroundStyle(colorPalette.onSurfaceVariant)

                        CodeSnippetView(
                            code: """
                            MarkdownView(source)
                                .markdownRenderingOptions(
                                    .init(renderMermaid: false)
                                )
                            """,
                            language: "swift"
                        )
                    }
                }

                // Supported diagram types
                CatalogSectionCard(title: "対応ダイアグラム") {
                    VStack(alignment: .leading, spacing: spacing.sm) {
                        diagramTypeRow("フローチャート", syntax: "graph TD/LR")
                        diagramTypeRow("シーケンス図", syntax: "sequenceDiagram")
                        diagramTypeRow("クラス図", syntax: "classDiagram")
                        diagramTypeRow("状態図", syntax: "stateDiagram-v2")
                        diagramTypeRow("ER図", syntax: "erDiagram")
                        diagramTypeRow("円グラフ", syntax: "pie")
                        diagramTypeRow("ガントチャート", syntax: "gantt")
                        diagramTypeRow("Git グラフ", syntax: "gitGraph")
                    }
                }
            }
            .padding(spacing.lg)
        }
        .background(colorPalette.background)
    }

    @ViewBuilder
    private func diagramTypeRow(_ name: String, syntax: String) -> some View {
        HStack {
            Text(name)
                .typography(.bodyMedium)
                .foregroundStyle(colorPalette.onSurface)

            Spacer()

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
        MermaidCatalogView()
            .navigationTitle("Mermaid")
    }
    .theme(ThemeProvider())
}
