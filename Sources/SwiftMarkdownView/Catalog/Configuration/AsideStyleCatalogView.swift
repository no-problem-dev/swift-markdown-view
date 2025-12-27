import SwiftUI
import DesignSystem

/// Catalog view for AsideStyle configuration.
public struct AsideStyleCatalogView: View {

    @Environment(\.colorPalette) private var colorPalette
    @Environment(\.spacingScale) private var spacing

    public init() {}

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: spacing.xl) {
                // Overview
                CatalogSectionCard(
                    title: "概要",
                    subtitle: "Aside（注釈ブロック）のスタイルをカスタマイズします"
                ) {
                    Text("AsideStyleプロトコルに準拠したスタイルを作成することで、Asideの外観を完全にカスタマイズできます。色、アイコン、レイアウトなどを制御できます。")
                        .typography(.bodyMedium)
                        .foregroundStyle(colorPalette.onSurfaceVariant)
                }

                // Default style
                CatalogSectionCard(title: "デフォルトスタイル") {
                    VStack(alignment: .leading, spacing: spacing.lg) {
                        MarkdownPreviewCard(
                            title: "Note",
                            markdownSource: """
                            > [!NOTE]
                            > これは補足情報です。
                            """
                        )

                        MarkdownPreviewCard(
                            title: "Tip",
                            markdownSource: """
                            > [!TIP]
                            > 便利なヒントです。
                            """
                        )

                        MarkdownPreviewCard(
                            title: "Important",
                            markdownSource: """
                            > [!IMPORTANT]
                            > 重要な情報です。
                            """
                        )

                        MarkdownPreviewCard(
                            title: "Warning",
                            markdownSource: """
                            > [!WARNING]
                            > 警告メッセージです。
                            """
                        )

                        MarkdownPreviewCard(
                            title: "Caution",
                            markdownSource: """
                            > [!CAUTION]
                            > 注意が必要です。
                            """
                        )
                    }
                }

                // AsideStyle protocol
                CatalogSectionCard(title: "AsideStyleプロトコル") {
                    VStack(alignment: .leading, spacing: spacing.md) {
                        Text("カスタムスタイルを作成するには、AsideStyleプロトコルに準拠します。")
                            .typography(.bodyMedium)
                            .foregroundStyle(colorPalette.onSurfaceVariant)

                        CodeSnippetView(
                            code: """
                            public protocol AsideStyle: Sendable {
                                func makeBody(
                                    kind: AsideKind,
                                    content: @escaping () -> AnyView
                                ) -> AnyView
                            }
                            """,
                            language: "swift"
                        )
                    }
                }

                // Custom style example
                CatalogSectionCard(title: "カスタムスタイル例") {
                    VStack(alignment: .leading, spacing: spacing.md) {
                        Text("独自のAsideスタイルを実装する例:")
                            .typography(.bodyMedium)
                            .foregroundStyle(colorPalette.onSurfaceVariant)

                        CodeSnippetView(
                            code: """
                            struct MinimalAsideStyle: AsideStyle {
                                func makeBody(
                                    kind: AsideKind,
                                    content: @escaping () -> AnyView
                                ) -> AnyView {
                                    AnyView(
                                        HStack(spacing: 12) {
                                            Rectangle()
                                                .fill(kind.color)
                                                .frame(width: 3)

                                            content()
                                        }
                                        .padding(.vertical, 8)
                                    )
                                }
                            }
                            """,
                            language: "swift"
                        )
                    }
                }

                // AsideKind
                CatalogSectionCard(title: "AsideKind") {
                    VStack(alignment: .leading, spacing: spacing.sm) {
                        kindRow("note", icon: "info.circle", description: "補足情報")
                        kindRow("tip", icon: "lightbulb", description: "ヒント・アドバイス")
                        kindRow("important", icon: "exclamationmark.circle", description: "重要な情報")
                        kindRow("warning", icon: "exclamationmark.triangle", description: "警告")
                        kindRow("caution", icon: "xmark.octagon", description: "注意・危険")
                    }
                }

                // Usage
                CatalogSectionCard(title: "使用例") {
                    CodeSnippetView(
                        code: """
                        // カスタムスタイルを適用
                        MarkdownView(source)
                            .markdownAsideStyle(MinimalAsideStyle())

                        // または環境値として設定
                        ContentView()
                            .environment(\\.asideStyle, MinimalAsideStyle())
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
    private func kindRow(_ name: String, icon: String, description: String) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(colorPalette.primary)
                .frame(width: 24)

            Text(name)
                .typography(.labelMedium)
                .fontDesign(.monospaced)
                .foregroundStyle(colorPalette.onSurface)
                .frame(width: 80, alignment: .leading)

            Text(description)
                .typography(.bodySmall)
                .foregroundStyle(colorPalette.onSurfaceVariant)
        }
        .padding(.vertical, spacing.xs)
    }
}

#Preview {
    NavigationStack {
        AsideStyleCatalogView()
            .navigationTitle("Asideスタイル")
    }
    .theme(ThemeProvider())
}
