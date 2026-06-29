import Foundation

/// Markdown ブロック内のインライン要素。
///
/// 段落やその他のブロック内のコンテンツ（テキスト・強調・リンク・インラインコードなど）を表す。
public enum MarkdownInline: Sendable, Equatable {

    /// プレーンテキスト。
    case text(String)

    /// 強調（斜体）コンテンツ。
    case emphasis([MarkdownInline])

    /// 強い強調（太字）コンテンツ。
    case strong([MarkdownInline])

    /// インラインコードスパン。
    case code(String)

    /// ハイパーリンク。
    case link(destination: String, title: String?, content: [MarkdownInline])

    /// 画像。
    case image(source: String, alt: String, title: String?)

    /// ソフト改行（コンテキストに応じてスペースまたは改行として描画）。
    case softBreak

    /// ハード改行（明示的な改行）。
    case hardBreak

    /// 取り消し線テキスト（GFM 拡張）。
    case strikethrough([MarkdownInline])

    /// LaTeX ソース（デリミターなし）を含むインライン数式。
    ///
    /// `$...$`（Pandoc ルール）および `\(...\)` で生成する。レンダリングは環境の ``MathRenderer`` に委譲する。
    case inlineMath(String)
}
