import SwiftUI
import DesignSystem

/// Catalog view for TableStyle configuration.
public struct TableStyleCatalogView: View {

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
                    subtitle: "テーブルの表示スタイルを制御します"
                ) {
                    Text("TableStyleプロトコルを使用して、テーブルの枠線、ストライプ、色、余白などをカスタマイズできます。データの可読性を高めるスタイルを選択できます。")
                        .typography(.bodyMedium)
                        .foregroundStyle(colorPalette.onSurfaceVariant)
                }

                // Table preview
                CatalogSectionCard(title: "テーブルプレビュー") {
                    VStack(alignment: .leading, spacing: spacing.lg) {
                        Text("現在のスタイルでのレンダリング:")
                            .typography(.bodyMedium)
                            .foregroundStyle(colorPalette.onSurfaceVariant)

                        MarkdownView(sampleTable)
                            .padding(spacing.md)
                            .background(colorPalette.surfaceVariant.opacity(0.3))
                            .clipShape(RoundedRectangle(cornerRadius: radius.md))
                    }
                }

                // Built-in styles
                CatalogSectionCard(title: "組み込みスタイル") {
                    VStack(alignment: .leading, spacing: spacing.lg) {
                        styleDescription(
                            "DefaultTableStyle",
                            features: ["標準の枠線", "ヘッダー背景色", "均等な余白"]
                        )

                        styleDescription(
                            "StripedTableStyle",
                            features: ["交互の行背景色", "視認性向上", "大量データに最適"]
                        )

                        styleDescription(
                            "BorderlessTableStyle",
                            features: ["枠線なし", "ミニマルなデザイン", "余白で区切り"]
                        )

                        styleDescription(
                            "CardTableStyle",
                            features: ["カード風の外観", "角丸", "シャドウ効果"]
                        )
                    }
                }

                // Protocol definition
                CatalogSectionCard(title: "TableStyleプロトコル") {
                    VStack(alignment: .leading, spacing: spacing.md) {
                        Text("カスタムスタイルを作成するためのプロトコル定義:")
                            .typography(.bodyMedium)
                            .foregroundStyle(colorPalette.onSurfaceVariant)

                        CodeSnippetView(
                            code: """
                            public protocol TableStyle: Sendable {
                                var showBorders: Bool { get }
                                var showStripes: Bool { get }
                                var headerBackgroundColor: Color { get }
                                var headerTextColor: Color { get }
                                var rowBackgroundColor: Color { get }
                                var alternateRowBackgroundColor: Color { get }
                                var borderColor: Color { get }
                                var cellPadding: EdgeInsets { get }
                            }
                            """,
                            language: "swift"
                        )
                    }
                }

                // Table alignment
                CatalogSectionCard(title: "列の配置") {
                    VStack(alignment: .leading, spacing: spacing.md) {
                        Text("Markdownでは列ごとに配置を指定できます:")
                            .typography(.bodyMedium)
                            .foregroundStyle(colorPalette.onSurfaceVariant)

                        VStack(alignment: .leading, spacing: spacing.sm) {
                            alignmentRow(":---", description: "左揃え")
                            alignmentRow(":---:", description: "中央揃え")
                            alignmentRow("---:", description: "右揃え")
                        }

                        MarkdownPreviewCard(
                            title: "配置の例",
                            markdownSource: """
                            | 左揃え | 中央揃え | 右揃え |
                            |:-------|:--------:|-------:|
                            | Left   | Center   | Right  |
                            | 1234   | 5678     | 9012   |
                            """
                        )
                    }
                }

                // Custom style example
                CatalogSectionCard(title: "カスタムスタイル例") {
                    CodeSnippetView(
                        code: """
                        struct CompactTableStyle: TableStyle {
                            let showBorders = true
                            let showStripes = false
                            let headerBackgroundColor = Color.blue.opacity(0.2)
                            let headerTextColor = Color.primary
                            let rowBackgroundColor = Color.clear
                            let alternateRowBackgroundColor = Color.clear
                            let borderColor = Color.gray.opacity(0.3)
                            let cellPadding = EdgeInsets(
                                top: 4, leading: 8,
                                bottom: 4, trailing: 8
                            )
                        }

                        MarkdownView(source)
                            .markdownTableStyle(CompactTableStyle())
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
                            .markdownTableStyle(StripedTableStyle())

                        // 環境値として設定
                        ContentView()
                            .environment(
                                \\.tableStyle,
                                CardTableStyle()
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

    private var sampleTable: String {
        """
        | 名前 | 役職 | 部署 |
        |------|------|------|
        | 田中 | 部長 | 営業 |
        | 佐藤 | 課長 | 開発 |
        | 鈴木 | 主任 | 総務 |
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

    @ViewBuilder
    private func alignmentRow(_ syntax: String, description: String) -> some View {
        HStack {
            Text(syntax)
                .typography(.bodySmall)
                .fontDesign(.monospaced)
                .foregroundStyle(colorPalette.primary)
                .frame(width: 60, alignment: .leading)

            Text(description)
                .typography(.bodySmall)
                .foregroundStyle(colorPalette.onSurfaceVariant)
        }
    }
}

#Preview {
    NavigationStack {
        TableStyleCatalogView()
            .navigationTitle("テーブルスタイル")
    }
    .theme(ThemeProvider())
}
