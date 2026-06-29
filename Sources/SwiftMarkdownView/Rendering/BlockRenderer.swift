import SwiftUI
import DesignSystem

#if os(macOS)
import AppKit
#else
import UIKit
#endif

/// ブロックレベルの Markdown 要素を SwiftUI ビューとしてレンダリングする。
///
/// `MarkdownBlock` 要素を適切な SwiftUI ビューに変換し、
/// DesignSystem トークンで一貫したスタイルを適用する。
enum BlockRenderer {

    /// ブロック配列を垂直スタックビューとしてレンダリングする。
    ///
    /// - Parameter blocks: レンダリングするブロック。
    /// - Returns: すべてのレンダリング済みブロックを含むビュー。
    @ViewBuilder
    static func render(_ blocks: [MarkdownBlock]) -> some View {
        BlockContainerView(blocks: blocks)
    }
}

// MARK: - Container View

/// DesignSystem 環境アクセスを提供するコンテナビュー。
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

/// 環境アクセス付きで単一ブロックをレンダリングする。
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

        case .math(let latex):
            MathBlockView(latex: latex)
        }
    }
}

// MARK: - Block Views

/// 段落ブロックをレンダリングする。
/// 段落が画像のみを含む場合、ブロックレベル画像としてレンダリングする。
struct ParagraphView: View {
    let inlines: [MarkdownInline]

    @Environment(\.colorPalette) private var colorPalette
    @Environment(\.mathRenderer) private var mathRenderer
    @Environment(\.markdownRenderingOptions) private var renderingOptions

    var body: some View {
        if let singleImage = extractSingleImage() {
            MarkdownImageView(
                source: singleImage.source,
                alt: singleImage.alt,
                title: singleImage.title
            )
        } else {
            let bodyTypography = MarkdownTypographyMapping.body
            InlineRenderer.render(
                inlines,
                colorPalette: colorPalette,
                bodyFont: bodyTypography.font,
                mathRenderer: renderingOptions.renderMath ? mathRenderer : nil
            )
            .lineSpacing(bodyTypography.lineHeight - bodyTypography.size)
            .foregroundStyle(MarkdownColors.bodyText(colorPalette))
            .fixedSize(horizontal: false, vertical: true)
        }
    }

    /// 段落が画像のみ（任意の空白を含む）を含む場合、その画像を抽出する。
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

/// リモート URL には AsyncImage を使用してブロックレベル画像をレンダリングする。
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
                                .mediaViewable(.image(url))
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
                .mediaViewable(.image(url))
        } else {
            errorView
        }
        #else
        if let uiImage = UIImage(contentsOfFile: url.path) {
            Image(uiImage: uiImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .mediaViewable(.image(url))
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

/// 適切なタイポグラフィで見出しブロックをレンダリングする。
struct HeadingView: View {
    let level: Int
    let content: [MarkdownInline]

    @Environment(\.colorPalette) private var colorPalette
    @Environment(\.spacingScale) private var spacing

    var body: some View {
        let headingTypography = MarkdownTypographyMapping.typography(for: level)
        InlineRenderer.render(content, colorPalette: colorPalette, bodyFont: headingTypography.font)
            .lineSpacing(headingTypography.lineHeight - headingTypography.size)
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

/// シンタックスハイライト付きでフェンスまたはインデントコードブロックをレンダリングする。
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

/// Aside（コールアウト/警告）ブロックをレンダリングする。
///
/// Aside はアイコン・タイトル・コンテンツ付きでレンダリングされる。
/// 外観スタイルは ``AsideStyle`` プロトコルで制御し、
/// ``SwiftUICore/View/asideStyle(_:)`` モディファイアでカスタマイズできる。
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

/// 順序なし（箇条書き）リストをレンダリングする。
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

/// 順序付き（番号付き）リストをレンダリングする。
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

/// 単一のリストアイテムをレンダリングする。
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

/// 区切り線（水平ルール）をレンダリングする。
struct ThematicBreakView: View {
    @Environment(\.colorPalette) private var colorPalette
    @Environment(\.spacingScale) private var spacing

    var body: some View {
        Divider()
            .background(colorPalette.outlineVariant)
            .padding(.vertical, spacing.sm)
    }
}

/// テーブルをレンダリングする。
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

/// 単一のテーブル行をレンダリングする。
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

/// 単一のテーブルセルをレンダリングする。
struct TableCellView: View {
    let content: [MarkdownInline]
    let alignment: TableAlignment
    let isHeader: Bool

    @Environment(\.colorPalette) private var colorPalette
    @Environment(\.spacingScale) private var spacing

    var body: some View {
        let cellTypography: Typography = isHeader ? .labelLarge : .bodyMedium
        InlineRenderer.render(content, colorPalette: colorPalette, bodyFont: cellTypography.font)
            .lineSpacing(cellTypography.lineHeight - cellTypography.size)
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
