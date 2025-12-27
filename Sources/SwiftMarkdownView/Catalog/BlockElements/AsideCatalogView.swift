import SwiftUI
import DesignSystem

/// Catalog view for aside (callout/admonition) elements.
public struct AsideCatalogView: View {

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
                    subtitle: "Asideは重要な情報を強調するコールアウトです"
                ) {
                    Text("ブロッククォート(`>`)の先頭に種類を指定することで、様々なスタイルのAsideを作成できます。Note、Warning、Tipなど24種類のビルトインタイプがあります。")
                        .typography(.bodyMedium)
                        .foregroundStyle(colorPalette.onSurfaceVariant)
                }

                // Common types
                CatalogSectionCard(title: "よく使われるタイプ") {
                    VStack(alignment: .leading, spacing: spacing.lg) {
                        MarkdownPreviewCard(
                            title: "Note",
                            description: "補足情報や参考情報",
                            markdownSource: "> Note: これは補足情報です。追加のコンテキストを提供します。"
                        )

                        MarkdownPreviewCard(
                            title: "Tip",
                            description: "便利なヒントやコツ",
                            markdownSource: "> Tip: この機能を使うと作業が効率化できます。"
                        )

                        MarkdownPreviewCard(
                            title: "Important",
                            description: "重要な情報",
                            markdownSource: "> Important: この設定は必ず確認してください。"
                        )

                        MarkdownPreviewCard(
                            title: "Warning",
                            description: "警告や注意事項",
                            markdownSource: "> Warning: この操作は取り消せません。実行前に必ず確認してください。"
                        )
                    }
                }

                // Additional types
                CatalogSectionCard(title: "その他のタイプ") {
                    VStack(alignment: .leading, spacing: spacing.lg) {
                        MarkdownPreviewCard(
                            title: "Experiment",
                            markdownSource: "> Experiment: この機能は実験的なものです。"
                        )

                        MarkdownPreviewCard(
                            title: "Bug",
                            markdownSource: "> Bug: 既知の問題があります。修正中です。"
                        )

                        MarkdownPreviewCard(
                            title: "ToDo",
                            markdownSource: "> ToDo: この機能は今後実装予定です。"
                        )

                        MarkdownPreviewCard(
                            title: "SeeAlso",
                            markdownSource: "> SeeAlso: 関連ドキュメントも参照してください。"
                        )
                    }
                }

                // With content
                CatalogSectionCard(title: "複数行のコンテンツ") {
                    MarkdownPreviewCard(
                        title: "複数行Aside",
                        markdownSource: """
                        > Note: Asideは複数行にわたるコンテンツを含めることができます。
                        >
                        > - リストアイテム1
                        > - リストアイテム2
                        >
                        > **太字**や*斜体*も使用できます。
                        """
                    )
                }

                // Available types list
                CatalogSectionCard(title: "利用可能なタイプ一覧") {
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: spacing.sm) {
                        ForEach(asideTypes, id: \.self) { type in
                            Text(type)
                                .typography(.labelMedium)
                                .fontDesign(.monospaced)
                                .padding(.horizontal, spacing.sm)
                                .padding(.vertical, spacing.xs)
                                .background(colorPalette.surfaceVariant)
                                .clipShape(RoundedRectangle(cornerRadius: radius.sm))
                        }
                    }
                }

                // Usage
                CatalogSectionCard(title: "使用例") {
                    CodeSnippetView(
                        code: """
                        MarkdownView(\"\"\"
                        > Warning: この操作は危険です。
                        \"\"\")
                        .asideStyle(MyCustomAsideStyle())
                        """,
                        language: "swift"
                    )
                }
            }
            .padding(spacing.lg)
        }
        .background(colorPalette.background)
    }

    private var asideTypes: [String] {
        [
            "Note", "Tip", "Important", "Warning",
            "Experiment", "Attention", "Author", "Authors",
            "Bug", "Complexity", "Copyright", "Date",
            "Invariant", "MutatingVariant", "NonMutatingVariant",
            "Postcondition", "Precondition", "Remark",
            "Requires", "Since", "ToDo", "Version",
            "Throws", "SeeAlso"
        ]
    }
}

#Preview {
    NavigationStack {
        AsideCatalogView()
            .navigationTitle("Aside")
    }
    .theme(ThemeProvider())
}
