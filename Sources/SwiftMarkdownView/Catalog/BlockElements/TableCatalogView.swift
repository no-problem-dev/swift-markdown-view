import SwiftUI
import DesignSystem

/// Catalog view for table elements.
public struct TableCatalogView: View {

    @Environment(\.colorPalette) private var colorPalette
    @Environment(\.spacingScale) private var spacing

    public init() {}

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: spacing.xl) {
                // Overview
                CatalogSectionCard(
                    title: "概要",
                    subtitle: "テーブルはデータを行列形式で表示します"
                ) {
                    Text("パイプ(`|`)で列を区切り、ハイフン(`---`)でヘッダーと本体を分けます。コロン(`:`)で列の配置を指定できます。")
                        .typography(.bodyMedium)
                        .foregroundStyle(colorPalette.onSurfaceVariant)
                }

                // Basic table
                CatalogSectionCard(title: "基本的なテーブル") {
                    MarkdownPreviewCard(
                        title: "シンプルなテーブル",
                        markdownSource: """
                        | 名前 | 年齢 | 職業 |
                        |------|------|------|
                        | 田中 | 30 | エンジニア |
                        | 佐藤 | 25 | デザイナー |
                        | 鈴木 | 35 | マネージャー |
                        """
                    )
                }

                // Column alignment
                CatalogSectionCard(title: "列の配置") {
                    VStack(alignment: .leading, spacing: spacing.lg) {
                        MarkdownPreviewCard(
                            title: "左揃え・中央揃え・右揃え",
                            description: "`:---` 左揃え、`:---:` 中央、`---:` 右揃え",
                            markdownSource: """
                            | 左揃え | 中央揃え | 右揃え |
                            |:-------|:--------:|-------:|
                            | テキスト | テキスト | テキスト |
                            | 左 | 中央 | 右 |
                            """
                        )
                    }
                }

                // With inline elements
                CatalogSectionCard(title: "インライン要素を含むテーブル") {
                    MarkdownPreviewCard(
                        title: "装飾付きセル",
                        markdownSource: """
                        | 機能 | 状態 | 備考 |
                        |------|------|------|
                        | ログイン | **完了** | テスト済み |
                        | 登録 | *進行中* | 50% |
                        | 決済 | `未着手` | Q2予定 |
                        """
                    )
                }

                // Numbers table
                CatalogSectionCard(title: "数値データのテーブル") {
                    MarkdownPreviewCard(
                        title: "売上データ",
                        markdownSource: """
                        | 月 | 売上 | 前月比 |
                        |:---|-----:|------:|
                        | 1月 | ¥100,000 | - |
                        | 2月 | ¥120,000 | +20% |
                        | 3月 | ¥150,000 | +25% |
                        """
                    )
                }

                // Empty cells
                CatalogSectionCard(title: "空のセル") {
                    MarkdownPreviewCard(
                        title: "一部のセルが空",
                        markdownSource: """
                        | 項目 | 値1 | 値2 |
                        |------|-----|-----|
                        | A | 100 | |
                        | B | | 200 |
                        | C | 150 | 180 |
                        """
                    )
                }

                // Usage
                CatalogSectionCard(title: "使用例") {
                    CodeSnippetView(
                        code: """
                        MarkdownView(\"\"\"
                        | 列1 | 列2 |
                        |-----|-----|
                        | A | B |
                        \"\"\")
                        .markdownTableStyle(StripedTableStyle())
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
        TableCatalogView()
            .navigationTitle("テーブル")
    }
    .theme(ThemeProvider())
}
