import SwiftUI
import DesignSystem

/// Catalog view for MarkdownRenderingOptions configuration.
public struct RenderingOptionsCatalogView: View {

    @Environment(\.colorPalette) private var colorPalette
    @Environment(\.spacingScale) private var spacing
    @Environment(\.radiusScale) private var radius

    @State private var options = MarkdownRenderingOptions.default

    public init() {}

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: spacing.xl) {
                // Overview
                CatalogSectionCard(
                    title: "概要",
                    subtitle: "Markdownのレンダリング動作を制御します"
                ) {
                    Text("MarkdownRenderingOptionsを使用して、どの要素をレンダリングするか、画像サイズの制限などを設定できます。Environmentを通じてアプリ全体または特定のビューに適用できます。")
                        .typography(.bodyMedium)
                        .foregroundStyle(colorPalette.onSurfaceVariant)
                }

                // Interactive demo
                CatalogSectionCard(title: "インタラクティブデモ") {
                    VStack(alignment: .leading, spacing: spacing.lg) {
                        // Toggle options
                        VStack(alignment: .leading, spacing: spacing.md) {
                            optionToggle("Mermaidを描画", isOn: $options.renderMermaid)
                            optionToggle("画像を描画", isOn: $options.renderImages)
                            optionToggle("テーブルを描画", isOn: $options.renderTables)
                            optionToggle("Asideを描画", isOn: $options.renderAsides)
                            optionToggle("シンタックスハイライト", isOn: $options.enableSyntaxHighlighting)
                        }

                        Divider()

                        // Preview
                        Text("プレビュー")
                            .typography(.labelMedium)
                            .foregroundStyle(colorPalette.onSurfaceVariant)

                        MarkdownView("""
                        # サンプル

                        通常のテキストです。

                        > [!NOTE]
                        > これはAsideです。

                        | 列1 | 列2 |
                        |-----|-----|
                        | A   | B   |

                        ```swift
                        let greeting = "Hello"
                        ```
                        """)
                        .markdownRenderingOptions(options)
                        .padding(spacing.md)
                        .background(colorPalette.surfaceVariant.opacity(0.3))
                        .clipShape(RoundedRectangle(cornerRadius: radius.md))
                    }
                }

                // Presets
                CatalogSectionCard(title: "プリセット") {
                    VStack(alignment: .leading, spacing: spacing.lg) {
                        presetRow(".default", description: "すべての機能を有効化") {
                            options = .default
                        }

                        presetRow(".compact", description: "画像なし、Mermaidなし") {
                            options = .compact
                        }

                        presetRow(".plainText", description: "最小限のレンダリング") {
                            options = .plainText
                        }
                    }
                }

                // Image size limits
                CatalogSectionCard(title: "画像サイズ制限") {
                    VStack(alignment: .leading, spacing: spacing.md) {
                        Text("maxImageHeightとmaxImageWidthで画像の最大サイズを制限できます。")
                            .typography(.bodyMedium)
                            .foregroundStyle(colorPalette.onSurfaceVariant)

                        CodeSnippetView(
                            code: """
                            MarkdownRenderingOptions(
                                maxImageHeight: 300,
                                maxImageWidth: 400
                            )
                            """,
                            language: "swift"
                        )
                    }
                }

                // Usage
                CatalogSectionCard(title: "使用例") {
                    VStack(alignment: .leading, spacing: spacing.lg) {
                        Text("View Modifier")
                            .typography(.labelMedium)
                            .foregroundStyle(colorPalette.onSurfaceVariant)

                        CodeSnippetView(
                            code: """
                            MarkdownView(source)
                                .markdownRenderingOptions(.compact)
                            """,
                            language: "swift"
                        )

                        Text("カスタム設定")
                            .typography(.labelMedium)
                            .foregroundStyle(colorPalette.onSurfaceVariant)

                        CodeSnippetView(
                            code: """
                            let customOptions = MarkdownRenderingOptions(
                                renderMermaid: true,
                                renderImages: true,
                                renderTables: true,
                                renderAsides: true,
                                maxImageHeight: 500,
                                maxImageWidth: nil,
                                enableSyntaxHighlighting: true
                            )

                            MarkdownView(source)
                                .markdownRenderingOptions(customOptions)
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

    @ViewBuilder
    private func optionToggle(_ label: String, isOn: Binding<Bool>) -> some View {
        Toggle(isOn: isOn) {
            Text(label)
                .typography(.bodyMedium)
                .foregroundStyle(colorPalette.onSurface)
        }
        .tint(colorPalette.primary)
    }

    @ViewBuilder
    private func presetRow(_ name: String, description: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: spacing.xs) {
                    Text(name)
                        .typography(.labelMedium)
                        .fontDesign(.monospaced)
                        .foregroundStyle(colorPalette.primary)

                    Text(description)
                        .typography(.bodySmall)
                        .foregroundStyle(colorPalette.onSurfaceVariant)
                }

                Spacer()

                Image(systemName: "arrow.right.circle")
                    .foregroundStyle(colorPalette.primary)
            }
            .padding(spacing.md)
            .background(colorPalette.surfaceVariant.opacity(0.5))
            .clipShape(RoundedRectangle(cornerRadius: radius.md))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationStack {
        RenderingOptionsCatalogView()
            .navigationTitle("レンダリングオプション")
    }
    .theme(ThemeProvider())
}
