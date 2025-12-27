import SwiftUI
import DesignSystem

/// A card that displays Markdown source and its rendered preview.
///
/// Use this component to demonstrate how Markdown syntax is rendered.
public struct MarkdownPreviewCard: View {

    /// The title for this preview card.
    public let title: String

    /// Optional description text.
    public let description: String?

    /// The Markdown source to display.
    public let markdownSource: String

    @Environment(\.colorPalette) private var colorPalette
    @Environment(\.spacingScale) private var spacing
    @Environment(\.radiusScale) private var radius

    @State private var showSource = false

    /// Creates a new Markdown preview card.
    ///
    /// - Parameters:
    ///   - title: The title for the card.
    ///   - description: Optional description text.
    ///   - markdownSource: The Markdown source to render.
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
