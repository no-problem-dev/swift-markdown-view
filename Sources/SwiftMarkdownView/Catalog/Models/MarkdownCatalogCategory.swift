import SwiftUI

/// Categories for the Markdown catalog.
///
/// Organizes catalog items into logical groups for navigation.
public enum MarkdownCatalogCategory: String, CaseIterable, Identifiable, Sendable {

    /// Block-level Markdown elements like headings, code blocks, lists.
    case blockElements = "ブロック要素"

    /// Inline Markdown elements like bold, italic, links.
    case inlineElements = "インライン要素"

    /// Configuration and styling options.
    case configuration = "設定"

    /// Interactive playground for testing Markdown.
    case playground = "プレイグラウンド"

    /// DesignSystem integration and theme settings.
    case designSystem = "デザインシステム"

    public var id: String { rawValue }

    /// The SF Symbol icon for this category.
    public var icon: String {
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

    /// A brief description of this category.
    public var description: String {
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

    /// The catalog items in this category.
    public var items: [MarkdownCatalogItem] {
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

/// Block-level element types for the catalog.
public enum BlockElementItem: String, CaseIterable, Identifiable, Sendable {
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

    public var id: String { rawValue }

    public var catalogItem: MarkdownCatalogItem {
        MarkdownCatalogItem(
            name: rawValue,
            icon: icon,
            description: description
        )
    }

    public var icon: String {
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

    public var description: String {
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

/// Inline element types for the catalog.
public enum InlineElementItem: String, CaseIterable, Identifiable, Sendable {
    case textStyles = "テキストスタイル"
    case inlineCode = "インラインコード"
    case link = "リンク"
    case softBreak = "改行"

    public var id: String { rawValue }

    public var catalogItem: MarkdownCatalogItem {
        MarkdownCatalogItem(
            name: rawValue,
            icon: icon,
            description: description
        )
    }

    public var icon: String {
        switch self {
        case .textStyles: return "bold.italic.underline"
        case .inlineCode: return "chevron.left.forwardslash.chevron.right"
        case .link: return "link"
        case .softBreak: return "return"
        }
    }

    public var description: String {
        switch self {
        case .textStyles: return "太字、斜体、取り消し線"
        case .inlineCode: return "文中のコードスニペット"
        case .link: return "ハイパーリンク"
        case .softBreak: return "ソフト改行とハード改行"
        }
    }
}

// MARK: - Configuration Items

/// Configuration and style options for the catalog.
public enum ConfigurationItem: String, CaseIterable, Identifiable, Sendable {
    case renderingOptions = "レンダリングオプション"
    case asideStyle = "Asideスタイル"
    case codeBlockStyle = "コードブロックスタイル"
    case headingStyle = "見出しスタイル"
    case tableStyle = "テーブルスタイル"
    case linkStyle = "リンクスタイル"
    case syntaxHighlighter = "シンタックスハイライト"

    public var id: String { rawValue }

    public var catalogItem: MarkdownCatalogItem {
        MarkdownCatalogItem(
            name: rawValue,
            icon: icon,
            description: description
        )
    }

    public var icon: String {
        switch self {
        case .renderingOptions: return "gearshape.fill"
        case .asideStyle: return "bubble.left.fill"
        case .codeBlockStyle: return "chevron.left.forwardslash.chevron.right"
        case .headingStyle: return "textformat.size"
        case .tableStyle: return "tablecells"
        case .linkStyle: return "link"
        case .syntaxHighlighter: return "paintbrush.fill"
        }
    }

    public var description: String {
        switch self {
        case .renderingOptions: return "Mermaid、画像、テーブルの有効/無効"
        case .asideStyle: return "コールアウトの見た目をカスタマイズ"
        case .codeBlockStyle: return "コードブロックのスタイル設定"
        case .headingStyle: return "見出しのタイポグラフィと色"
        case .tableStyle: return "テーブルのボーダーと色"
        case .linkStyle: return "リンクの色と下線"
        case .syntaxHighlighter: return "コードハイライトのテーマ"
        }
    }
}

// MARK: - DesignSystem Items

/// DesignSystem integration items for the catalog.
public enum DesignSystemItem: String, CaseIterable, Identifiable, Sendable {
    case fullCatalog = "デザインシステムカタログ"

    public var id: String { rawValue }

    public var catalogItem: MarkdownCatalogItem {
        MarkdownCatalogItem(
            name: rawValue,
            icon: icon,
            description: description
        )
    }

    public var icon: String {
        switch self {
        case .fullCatalog: return "paintpalette.fill"
        }
    }

    public var description: String {
        switch self {
        case .fullCatalog: return "テーマ、カラー、タイポグラフィ、スペーシングなど"
        }
    }
}
