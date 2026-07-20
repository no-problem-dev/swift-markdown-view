import SwiftMarkdownView
import SwiftUI
import DesignSystem

/// Markdown ソースとそのレンダリング結果を並べて表示するカード。
///
/// Markdown 構文がどのようにレンダリングされるかを示す際に使用する。
public struct MarkdownPreviewCard: View {

    /// このプレビューカードのタイトル。
    public let title: String

    /// オプションの説明テキスト。
    public let description: String?

    /// 表示する Markdown ソース。
    public let markdownSource: String

    @Environment(\.colorPalette) private var colorPalette
    @Environment(\.spacingScale) private var spacing
    @Environment(\.radiusScale) private var radius

    @State private var showSource = false

    /// Markdown プレビューカードを作成する。
    ///
    /// - Parameters:
    ///   - title: カードのタイトル。
    ///   - description: オプションの説明テキスト。
    ///   - markdownSource: レンダリングする Markdown ソース。
    public init(
        title: String,
        description: String? = nil,
        markdownSource: String
    ) {
        self.title = title
        self.description = description
        self.markdownSource = markdownSource
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: spacing.md) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: spacing.xs) {
                    Text(title)
                        .typography(.titleMedium)
                        .foregroundStyle(colorPalette.onSurface)

                    if let description {
                        Text(description)
                            .typography(.bodySmall)
                            .foregroundStyle(colorPalette.onSurfaceVariant)
                    }
                }

                Spacer()

                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showSource.toggle()
                    }
                } label: {
                    Label(
                        showSource ? "プレビュー" : "ソース",
                        systemImage: showSource ? "eye" : "chevron.left.forwardslash.chevron.right"
                    )
                    .typography(.labelMedium)
                }
                .buttonStyle(.bordered)
            }

            // Content
            if showSource {
                sourceView
            } else {
                previewView
            }
        }
        .padding(spacing.md)
        .background(colorPalette.surface)
        .clipShape(RoundedRectangle(cornerRadius: radius.md))
        .overlay(
            RoundedRectangle(cornerRadius: radius.md)
                .stroke(colorPalette.outlineVariant, lineWidth: 1)
        )
    }

    @ViewBuilder
    private var sourceView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HighlightedCodeView(code: markdownSource, language: "markdown")
        }
        .padding(spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(colorPalette.surfaceVariant)
        .clipShape(RoundedRectangle(cornerRadius: radius.sm))
    }

    @ViewBuilder
    private var previewView: some View {
        MarkdownView(markdownSource)
            .padding(spacing.sm)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(colorPalette.background)
            .clipShape(RoundedRectangle(cornerRadius: radius.sm))
    }
}

#Preview {
    MarkdownPreviewCard(
        title: "見出し H1",
        description: "最も大きな見出し",
        markdownSource: "# Hello World"
    )
    .padding()
    .theme(ThemeProvider())
}
