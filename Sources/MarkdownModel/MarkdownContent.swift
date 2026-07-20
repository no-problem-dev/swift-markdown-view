import Foundation

/// Markdown ドキュメントをブロックのコレクションとして表したパース済みの値型。
///
/// 一度生成すれば複数のレンダリングに使い回せる。
///
/// ```swift
/// let content = MarkdownContent(parsing: "# Hello **World**")
/// MarkdownView(content)
/// ```
public struct MarkdownContent: Sendable, Equatable {

    /// このコンテンツのブロックレベル要素。
    public let blocks: [MarkdownBlock]

    /// Markdown 文字列をパースして MarkdownContent を生成する。
    ///
    /// - Parameter source: パースする Markdown 文字列。
    public init(parsing source: String) {
        self.blocks = MarkdownParser.parse(source)
    }

    /// ブロックを直接指定して MarkdownContent を生成する。
    ///
    /// パース結果を加工してから描画したい場合に使う。たとえば見出しレベルを
    /// 一段下げる、特定のブロックを差し替える、複数ドキュメントを連結する:
    ///
    /// ```swift
    /// let parsed = MarkdownContent(parsing: source)
    /// let withoutImages = MarkdownContent(blocks: parsed.blocks.filter { block in
    ///     if case .paragraph(let inlines) = block, inlines.count == 1,
    ///        case .image = inlines[0] { return false }
    ///     return true
    /// })
    /// MarkdownView(withoutImages)
    /// ```
    ///
    /// - Parameter blocks: ブロックレベル要素。
    public init(blocks: [MarkdownBlock]) {
        self.blocks = blocks
    }
}
