import SwiftUI
import DesignSystem

#if os(macOS)
import AppKit
#else
import UIKit
#endif

/// Renders block-level Markdown elements as SwiftUI Views.
///
/// This renderer converts `MarkdownBlock` elements into appropriate SwiftUI views,
/// using DesignSystem tokens for consistent styling.
enum BlockRenderer {

    /// Renders an array of blocks as a vertically stacked view.
    ///
    /// - Parameter blocks: The blocks to render.
    /// - Returns: A view containing all rendered blocks.
    @ViewBuilder
    static func render(_ blocks: [MarkdownBlock]) -> some View {
        BlockContainerView(blocks: blocks)
    }
}

// MARK: - Container View

/// Container view that provides DesignSystem environment access.
struct BlockContainerView: View {
    let blocks: [MarkdownBlock]

    @Environment(\.spacingScale) private var spacing

    var body: some View {
        VStack(alignment: .leading, spacing: MarkdownSpacing.blockSpacing(spacing)) {
            ForEach(Array(blocks.enumerated()), id: \.offset) { _, block in
                BlockView(block: block)
            }
        }
    }
}

/// Renders a single block with environment access.
struct BlockView: View {
    let block: MarkdownBlock

    var body: some View {
        switch block {
        case .paragraph(let inlines):
            ParagraphView(inlines: inlines)

        case .heading(let level, let content):
            HeadingView(level: level, content: content)

        case .codeBlock(let language, let code):
            CodeBlockView(language: language, code: code)

        case .aside(let kind, let content):
            AsideView(kind: kind, content: content)

        case .unorderedList(let items):
            UnorderedListView(items: items)

        case .orderedList(let start, let items):
            OrderedListView(start: start, items: items)

        case .thematicBreak:
            ThematicBreakView()

        case .table(let tableData):
            TableView(data: tableData)

        case .mermaid(let code):
            AdaptiveMermaidView(code)
        }
    }
}

// MARK: - Block Views

/// Renders a paragraph block.
/// If the paragraph contains only an image, renders it as a block-level image.
struct ParagraphView: View {
    let inlines: [MarkdownInline]

    @Environment(\.colorPalette) private var colorPalette

    var body: some View {
        if let singleImage = extractSingleImage() {
            MarkdownImageView(
                source: singleImage.source,
                alt: singleImage.alt,
                title: singleImage.title
            )
        } else {
            InlineRenderer.render(inlines, colorPalette: colorPalette)
                .typography(MarkdownTypographyMapping.body)
                .foregroundStyle(MarkdownColors.bodyText(colorPalette))
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    /// Extracts a single image if the paragraph contains only an image (with optional whitespace).
    private func extractSingleImage() -> (source: String, alt: String, title: String?)? {
        let nonWhitespace = inlines.filter { inline in
            switch inline {
            case .text(let text):
                return !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            case .softBreak, .hardBreak:
                return false
            default:
                return true
            }
        }

        guard nonWhitespace.count == 1,
              case .image(let source, let alt, let title) = nonWhitespace.first else {
            return nil
        }

        return (source, alt, title)
    }
}

/// Renders a block-level image with AsyncImage for remote URLs.
struct MarkdownImageView: View {
    let source: String
    let alt: String
    let title: String?

    @Environment(\.colorPalette) private var colorPalette
    @Environment(\.spacingScale) private var spacing
    @Environment(\.radiusScale) private var radius

    var body: some View {
        Group {
            if let url = URL(string: source) {
                if url.scheme == "https" || url.scheme == "http" {
                    // Remote image with AsyncImage
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            placeholderView
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                        case .failure:
                            errorView
                        @unknown default:
                            placeholderView
                        }
                    }
                } else if url.scheme == "file", url.isFileURL {
                    // Local file image
                    localFileImage(url: url)
                } else {
                    fallbackView
                }
            } else {
                fallbackView
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .clipShape(RoundedRectangle(cornerRadius: radius.sm))
    }

    @ViewBuilder
    private func localFileImage(url: URL) -> some View {
        #if os(macOS)
        if let nsImage = NSImage(contentsOf: url) {
            Image(nsImage: nsImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
        } else {
            errorView
        }
        #else
        if let uiImage = UIImage(contentsOfFile: url.path) {
            Image(uiImage: uiImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
        } else {
            errorView
        }
        #endif
    }

    private var placeholderView: some View {
        HStack {
            ProgressView()
            if !alt.isEmpty {
                Text(alt)
                    .typography(.bodySmall)
                    .foregroundStyle(colorPalette.onSurfaceVariant)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 120)
        .background(colorPalette.surfaceVariant.opacity(0.5))
    }

    private var errorView: some View {
        VStack(spacing: spacing.xs) {
            Image(systemName: "photo")
                .font(.title)
                .foregroundStyle(colorPalette.onSurfaceVariant)
            if !alt.isEmpty {
                Text(alt)
                    .typography(.bodySmall)
                    .foregroundStyle(colorPalette.onSurfaceVariant)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 120)
        .background(colorPalette.surfaceVariant.opacity(0.5))
    }

    private var fallbackView: some View {
        VStack(spacing: spacing.xs) {
            Image(systemName: "photo")
                .font(.title)
                .foregroundStyle(colorPalette.onSurfaceVariant)
            Text(alt.isEmpty ? "Image" : alt)
                .typography(.bodySmall)
                .foregroundStyle(colorPalette.onSurfaceVariant)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 120)
        .background(colorPalette.surfaceVariant.opacity(0.5))
    }
}

/// Renders a heading block with appropriate typography.
struct HeadingView: View {
    let level: Int
    let content: [MarkdownInline]

    @Environment(\.colorPalette) private var colorPalette
    @Environment(\.spacingScale) private var spacing

    var body: some View {
        InlineRenderer.render(content, colorPalette: colorPalette)
            .typography(MarkdownTypographyMapping.typography(for: level))
            .foregroundStyle(MarkdownColors.headingText(colorPalette))
            .padding(.top, topPadding)
    }

    private var topPadding: CGFloat {
        switch level {
        case 1: return MarkdownSpacing.heading1TopPadding(spacing)
        case 2: return MarkdownSpacing.heading2TopPadding(spacing)
        default: return MarkdownSpacing.headingTopPadding(spacing)
        }
    }
}

/// Renders a fenced or indented code block with syntax highlighting.
struct CodeBlockView: View {
    let language: String?
    let code: String

    @Environment(\.colorPalette) private var colorPalette
    @Environment(\.spacingScale) private var spacing
    @Environment(\.radiusScale) private var radius

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let language = language, !language.isEmpty {
                Text(language)
                    .typography(.labelSmall)
                    .foregroundStyle(MarkdownColors.codeText(colorPalette))
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HighlightedCodeView(
                    code: trimmedCode,
                    language: language
                )
            }
            .padding(MarkdownSpacing.codeBlockPadding(spacing))
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(MarkdownColors.codeBlockBackground(colorPalette))
            .clipShape(RoundedRectangle(cornerRadius: MarkdownRadius.codeBlock(radius)))
        }
    }

    private var trimmedCode: String {
        code.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

/// Renders an aside (callout/admonition) block.
///
/// Asides are rendered with an icon, title, and content.
/// The visual styling is controlled by the ``AsideStyle`` protocol,
/// which can be customized using the ``SwiftUICore/View/asideStyle(_:)`` modifier.
struct AsideView: View {
    let kind: AsideKind
    let content: [MarkdownBlock]

    @Environment(\.colorPalette) private var colorPalette
    @Environment(\.spacingScale) private var spacing
    @Environment(\.radiusScale) private var radius
    @Environment(\.asideStyle) private var asideStyle

    var body: some View {
        VStack(alignment: .leading, spacing: spacing.sm) {
            // Header with icon and title
            HStack(spacing: spacing.sm) {
                Image(systemName: asideStyle.icon(for: kind))
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(asideStyle.accentColor(for: kind, colorPalette: colorPalette))

                Text(kind.displayName)
                    .typography(.labelLarge)
                    .fontWeight(.semibold)
                    .foregroundStyle(asideStyle.titleColor(for: kind, colorPalette: colorPalette))
            }

            // Content blocks
            if !content.isEmpty {
                VStack(alignment: .leading, spacing: spacing.sm) {
                    ForEach(Array(content.enumerated()), id: \.offset) { _, block in
                        BlockView(block: block)
                    }
                }
                .foregroundStyle(colorPalette.onSurface)
            }
        }
        .padding(spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(asideStyle.backgroundColor(for: kind, colorPalette: colorPalette))
        .overlay(alignment: .leading) {
            Rectangle()
                .fill(asideStyle.accentColor(for: kind, colorPalette: colorPalette))
                .frame(width: 4)
        }
        .clipShape(RoundedRectangle(cornerRadius: radius.md))
    }
}

/// Renders an unordered (bulleted) list.
struct UnorderedListView: View {
    let items: [ListItem]

    @Environment(\.spacingScale) private var spacing

    var body: some View {
        VStack(alignment: .leading, spacing: spacing.xs) {
            ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                ListItemView(bullet: "•", item: item)
            }
        }
    }
}

/// Renders an ordered (numbered) list.
struct OrderedListView: View {
    let start: Int
    let items: [ListItem]

    @Environment(\.spacingScale) private var spacing

    var body: some View {
        VStack(alignment: .leading, spacing: spacing.xs) {
            ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                ListItemView(bullet: "\(start + index).", item: item)
            }
        }
    }
}

/// Renders a single list item.
struct ListItemView: View {
    let bullet: String
    let item: ListItem

    @Environment(\.colorPalette) private var colorPalette
    @Environment(\.spacingScale) private var spacing

    var body: some View {
        HStack(alignment: .top, spacing: spacing.sm) {
            if let isChecked = item.isChecked {
                // Task list item
                Image(systemName: isChecked ? "checkmark.square.fill" : "square")
                    .foregroundStyle(isChecked ? colorPalette.primary : MarkdownColors.listBullet(colorPalette))
            } else {
                // Regular list item
                Text(bullet)
                    .foregroundStyle(MarkdownColors.listBullet(colorPalette))
            }

            VStack(alignment: .leading, spacing: spacing.xs) {
                ForEach(Array(item.blocks.enumerated()), id: \.offset) { _, block in
                    BlockView(block: block)
                }
            }
        }
        .padding(.leading, MarkdownSpacing.listIndent(spacing))
    }
}

/// Renders a thematic break (horizontal rule).
struct ThematicBreakView: View {
    @Environment(\.colorPalette) private var colorPalette
    @Environment(\.spacingScale) private var spacing

    var body: some View {
        Divider()
            .background(colorPalette.outlineVariant)
            .padding(.vertical, spacing.sm)
    }
}

/// Renders a table.
struct TableView: View {
    let data: TableData

    @Environment(\.colorPalette) private var colorPalette
    @Environment(\.spacingScale) private var spacing
    @Environment(\.radiusScale) private var radius

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header row
            TableRowView(
                cells: data.headerRow.cells,
                alignments: data.columnAlignments,
                isHeader: true
            )

            // Divider between header and body
            Rectangle()
                .fill(colorPalette.outlineVariant)
                .frame(height: 1)

            // Body rows
            ForEach(Array(data.bodyRows.enumerated()), id: \.offset) { index, row in
                TableRowView(
                    cells: row.cells,
                    alignments: data.columnAlignments,
                    isHeader: false
                )

                // Row separator (except for last row)
                if index < data.bodyRows.count - 1 {
                    Rectangle()
                        .fill(colorPalette.outlineVariant.opacity(0.5))
                        .frame(height: 1)
                }
            }
        }
        .background(colorPalette.surface)
        .clipShape(RoundedRectangle(cornerRadius: radius.sm))
        .overlay(
            RoundedRectangle(cornerRadius: radius.sm)
                .stroke(colorPalette.outlineVariant, lineWidth: 1)
        )
    }
}

/// Renders a single table row.
struct TableRowView: View {
    let cells: [[MarkdownInline]]
    let alignments: [TableAlignment]
    let isHeader: Bool

    @Environment(\.colorPalette) private var colorPalette
    @Environment(\.spacingScale) private var spacing

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(cells.enumerated()), id: \.offset) { index, cellContent in
                TableCellView(
                    content: cellContent,
                    alignment: alignments.indices.contains(index) ? alignments[index] : .none,
                    isHeader: isHeader
                )

                // Column separator (except for last column)
                if index < cells.count - 1 {
                    Rectangle()
                        .fill(colorPalette.outlineVariant.opacity(0.3))
                        .frame(width: 1)
                }
            }
        }
        .background(isHeader ? colorPalette.surfaceVariant.opacity(0.5) : Color.clear)
    }
}

/// Renders a single table cell.
struct TableCellView: View {
    let content: [MarkdownInline]
    let alignment: TableAlignment
    let isHeader: Bool

    @Environment(\.colorPalette) private var colorPalette
    @Environment(\.spacingScale) private var spacing

    var body: some View {
        InlineRenderer.render(content, colorPalette: colorPalette)
            .typography(isHeader ? .labelLarge : .bodyMedium)
            .fontWeight(isHeader ? .semibold : .regular)
            .foregroundStyle(colorPalette.onSurface)
            .frame(maxWidth: .infinity, alignment: textAlignment)
            .padding(.horizontal, spacing.sm)
            .padding(.vertical, spacing.xs)
    }

    private var textAlignment: Alignment {
        switch alignment {
        case .left, .none:
            return .leading
        case .center:
            return .center
        case .right:
            return .trailing
        }
    }
}
