import SwiftMarkdownView
import SwiftUI

/// A top-level grouping of catalog items, and the unit of navigation in the sidebar.
///
/// The raw value is the heading shown to the reader.
internal enum MarkdownCatalogCategory: String, CaseIterable, Identifiable, Sendable {

    /// Block-level elements: headings, code blocks, lists, tables, and so on.
    case blockElements = "ブロック要素"

    /// Inline elements: bold, italic, links, inline code.
    case inlineElements = "インライン要素"

    /// Rendering options, such as the syntax highlighter.
    case configuration = "設定"

    /// A live editor for trying Markdown by hand.
    case playground = "プレイグラウンド"

    /// Theming and design-token integration.
    case designSystem = "デザインシステム"

    internal var id: String { rawValue }

    internal var icon: String {
        switch self {
        case .blockElements:
            return "square.stack.3d.up.fill"
        case .inlineElements:
            return "textformat"
        case .configuration:
            return "slider.horizontal.3"
        case .playground:
            return "play.square.fill"
        case .designSystem:
            return "paintpalette.fill"
        }
    }

    internal var description: String {
        switch self {
        case .blockElements:
            return "見出し、コードブロック、リスト、テーブルなど"
        case .inlineElements:
            return "太字、斜体、リンク、インラインコードなど"
        case .configuration:
            return "スタイル設定とカスタマイズオプション"
        case .playground:
            return "Markdownをリアルタイムで試す"
        case .designSystem:
            return "テーマとデザイントークン"
        }
    }

    /// The rows to show for this category, built fresh on every access.
    ///
    /// Each call mints new identifiers, so items read from two calls never compare equal.
    /// Read the list once and keep it if you need the values to stay comparable.
    internal var items: [MarkdownCatalogItem] {
        switch self {
        case .blockElements:
            return BlockElementItem.allCases.map { $0.catalogItem }
        case .inlineElements:
            return InlineElementItem.allCases.map { $0.catalogItem }
        case .configuration:
            return ConfigurationItem.allCases.map { $0.catalogItem }
        case .playground:
            return [
                MarkdownCatalogItem(
                    name: "Markdownプレイグラウンド",
                    icon: "play.square.fill",
                    description: "自由にMarkdownを入力してリアルタイムプレビュー"
                )
            ]
        case .designSystem:
            return DesignSystemItem.allCases.map { $0.catalogItem }
        }
    }
}

// MARK: - Block Element Items

/// The block-level elements the catalog covers.
///
/// The raw value is both the row label and the key the router matches on, so renaming a
/// case's raw value breaks navigation to its screen.
internal enum BlockElementItem: String, CaseIterable, Identifiable, Sendable {
    case heading = "見出し"
    case paragraph = "段落"
    case codeBlock = "コードブロック"
    case aside = "Aside"
    case unorderedList = "順序なしリスト"
    case orderedList = "順序付きリスト"
    case taskList = "タスクリスト"
    case table = "テーブル"
    case mermaid = "Mermaid"
    case thematicBreak = "水平線"
    case image = "画像"

    internal var id: String { rawValue }

    internal var catalogItem: MarkdownCatalogItem {
        MarkdownCatalogItem(
            name: rawValue,
            icon: icon,
            description: description
        )
    }

    internal var icon: String {
        switch self {
        case .heading: return "textformat.size"
        case .paragraph: return "text.alignleft"
        case .codeBlock: return "chevron.left.forwardslash.chevron.right"
        case .aside: return "bubble.left.fill"
        case .unorderedList: return "list.bullet"
        case .orderedList: return "list.number"
        case .taskList: return "checklist"
        case .table: return "tablecells"
        case .mermaid: return "chart.bar.xaxis"
        case .thematicBreak: return "minus"
        case .image: return "photo"
        }
    }

    internal var description: String {
        switch self {
        case .heading: return "H1〜H6の見出しレベル"
        case .paragraph: return "テキスト段落"
        case .codeBlock: return "シンタックスハイライト付きコード"
        case .aside: return "Note、Warning、Tipなどのコールアウト"
        case .unorderedList: return "箇条書きリスト"
        case .orderedList: return "番号付きリスト"
        case .taskList: return "チェックボックス付きリスト"
        case .table: return "行列形式のデータ表示"
        case .mermaid: return "ダイアグラムとフローチャート"
        case .thematicBreak: return "セクション区切り線"
        case .image: return "画像の埋め込み"
        }
    }
}

// MARK: - Inline Element Items

/// The inline elements the catalog covers.
///
/// The raw value doubles as the router's lookup key, as in ``BlockElementItem``.
internal enum InlineElementItem: String, CaseIterable, Identifiable, Sendable {
    case textStyles = "テキストスタイル"
    case inlineCode = "インラインコード"
    case link = "リンク"
    case softBreak = "改行"

    internal var id: String { rawValue }

    internal var catalogItem: MarkdownCatalogItem {
        MarkdownCatalogItem(
            name: rawValue,
            icon: icon,
            description: description
        )
    }

    internal var icon: String {
        switch self {
        case .textStyles: return "bold.italic.underline"
        case .inlineCode: return "chevron.left.forwardslash.chevron.right"
        case .link: return "link"
        case .softBreak: return "return"
        }
    }

    internal var description: String {
        switch self {
        case .textStyles: return "太字、斜体、取り消し線"
        case .inlineCode: return "文中のコードスニペット"
        case .link: return "ハイパーリンク"
        case .softBreak: return "ソフト改行とハード改行"
        }
    }
}

// MARK: - Configuration Items

/// The rendering options the catalog covers.
///
/// The raw value doubles as the router's lookup key, as in ``BlockElementItem``.
internal enum ConfigurationItem: String, CaseIterable, Identifiable, Sendable {
    case syntaxHighlighter = "シンタックスハイライト"

    internal var id: String { rawValue }

    internal var catalogItem: MarkdownCatalogItem {
        MarkdownCatalogItem(
            name: rawValue,
            icon: icon,
            description: description
        )
    }

    internal var icon: String {
        switch self {
        case .syntaxHighlighter: return "paintbrush.fill"
        }
    }

    internal var description: String {
        switch self {
        case .syntaxHighlighter: return "コードハイライトのテーマ"
        }
    }
}

// MARK: - DesignSystem Items

/// The design-system screens reachable from the catalog.
///
/// The raw value doubles as the router's lookup key, as in ``BlockElementItem``.
internal enum DesignSystemItem: String, CaseIterable, Identifiable, Sendable {
    case fullCatalog = "デザインシステムカタログ"

    internal var id: String { rawValue }

    internal var catalogItem: MarkdownCatalogItem {
        MarkdownCatalogItem(
            name: rawValue,
            icon: icon,
            description: description
        )
    }

    internal var icon: String {
        switch self {
        case .fullCatalog: return "paintpalette.fill"
        }
    }

    internal var description: String {
        switch self {
        case .fullCatalog: return "テーマ、カラー、タイポグラフィ、スペーシングなど"
        }
    }
}
