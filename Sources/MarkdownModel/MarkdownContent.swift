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
    /// - Parameter blocks: ブロックレベル要素。
    internal init(blocks: [MarkdownBlock]) {
        self.blocks = blocks
    }
}
