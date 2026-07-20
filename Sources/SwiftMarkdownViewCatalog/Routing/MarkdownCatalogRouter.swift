import SwiftMarkdownView
import SwiftUI
import DesignSystem

/// カタログ View 間のナビゲーションを担当するルーター。
///
/// カテゴリとアイテムの選択に基づき、型安全に Detail ビューへ遷移する。
@MainActor
enum MarkdownCatalogRouter {

    /// カテゴリとアイテムに対応する Detail ビューを返す。
    ///
    /// - Parameters:
    ///   - category: 選択されたカテゴリ。
    ///   - item: カテゴリ内で選択されたアイテム。
    /// - Returns: 対応する Detail ビュー。
    @ViewBuilder
    static func destination(
        for category: MarkdownCatalogCategory,
        item: MarkdownCatalogItem
    ) -> some View {
        switch category {
        case .blockElements:
            destinationForBlockElement(item: item)
        case .inlineElements:
            destinationForInlineElement(item: item)
        case .configuration:
            destinationForConfiguration(item: item)
        case .playground:
            MarkdownPlaygroundView()
        case .designSystem:
            destinationForDesignSystem(item: item)
        }
    }

    // MARK: - Block Elements

    @ViewBuilder
    private static func destinationForBlockElement(item: MarkdownCatalogItem) -> some View {
        if let blockItem = BlockElementItem.allCases.first(where: { $0.rawValue == item.name }) {
            switch blockItem {
            case .heading:
                HeadingCatalogView()
            case .paragraph:
                ParagraphCatalogView()
            case .codeBlock:
                CodeBlockCatalogView()
            case .aside:
                AsideCatalogView()
            case .unorderedList:
                UnorderedListCatalogView()
            case .orderedList:
                OrderedListCatalogView()
            case .taskList:
                TaskListCatalogView()
            case .table:
                TableCatalogView()
            case .mermaid:
                MermaidCatalogView()
            case .thematicBreak:
                ThematicBreakCatalogView()
            case .image:
                ImageCatalogView()
            }
        } else {
            notFoundView(item: item)
        }
    }

    // MARK: - Inline Elements

    @ViewBuilder
    private static func destinationForInlineElement(item: MarkdownCatalogItem) -> some View {
        if let inlineItem = InlineElementItem.allCases.first(where: { $0.rawValue == item.name }) {
            switch inlineItem {
            case .textStyles:
                TextStylesCatalogView()
            case .inlineCode:
                InlineCodeCatalogView()
            case .link:
                LinkCatalogView()
            case .softBreak:
                SoftBreakCatalogView()
            }
        } else {
            notFoundView(item: item)
        }
    }

    // MARK: - Configuration

    @ViewBuilder
    private static func destinationForConfiguration(item: MarkdownCatalogItem) -> some View {
        if let configItem = ConfigurationItem.allCases.first(where: { $0.rawValue == item.name }) {
            switch configItem {
            case .renderingOptions:
                RenderingOptionsCatalogView()
            case .asideStyle:
                AsideStyleCatalogView()
            case .codeBlockStyle:
                CodeBlockStyleCatalogView()
            case .headingStyle:
                HeadingStyleCatalogView()
            case .tableStyle:
                TableStyleCatalogView()
            case .linkStyle:
                LinkStyleCatalogView()
            case .syntaxHighlighter:
                SyntaxHighlighterCatalogView()
            }
        } else {
            notFoundView(item: item)
        }
    }

    // MARK: - DesignSystem

    @ViewBuilder
    private static func destinationForDesignSystem(item: MarkdownCatalogItem) -> some View {
        if let dsItem = DesignSystemItem.allCases.first(where: { $0.rawValue == item.name }) {
            switch dsItem {
            case .fullCatalog:
                DesignSystemCatalogView()
            }
        } else {
            notFoundView(item: item)
        }
    }

    // MARK: - Not Found

    @ViewBuilder
    private static func notFoundView(item: MarkdownCatalogItem) -> some View {
        ContentUnavailableView(
            "アイテムが見つかりません",
            systemImage: "exclamationmark.triangle",
            description: Text("\(item.name) は現在利用できません")
        )
    }
}
