import Foundation

/// ソース側のシンタックスハイライトに使用する Markdown ソースの構文トークン。
///
/// トークンは ``TextSpan``（UTF-16 オフセット）と ``Kind`` を保持する。
/// TextKit 層は各 kind をテキスト属性にマッピングする。
/// トークンは重複しないため、`NSAttributedString` に左から右への単一パスで適用できる。
public struct MarkdownToken: Equatable, Sendable {

    /// トークンのカテゴリ。
    /// セットは意図的に小さく、ソースモード向け（マーカーを着色・範囲に色付け）。
    /// 完全なインラインマッチングはライブプレビューで扱う。
    public enum Kind: Equatable, Hashable, Sendable, CaseIterable {
        /// ATX 見出しを開く `#` ラン。
        case headingMarker
        /// 見出し行のテキスト（マーカーの後）。
        case heading
        /// 長さ 1 の `*`/`_` ラン（emphasis デリミタ）。
        case emphasis
        /// 長さ 2 以上の `*`/`_` ラン（strong デリミタ）。
        case strong
        /// `~~` ラン（取り消し線デリミタ）。
        case strikethrough
        /// インラインコードスパン（バッククォートを含む）。
        case inlineCode
        /// フェンスコードブロックのデリミタ行（```` ``` ```` / `~~~`）。
        case codeFence
        /// フェンスコードブロック内のコンテンツ行。
        case codeBlock
        /// リストの箇条書き・番号マーカー（`-`・`*`・`+`・`1.`）。
        case listMarker
        /// タスクリストのチェックボックス（`[ ]` / `[x]`）。
        case taskMarker
        /// blockquote の `>` マーカーラン。
        case blockquote
        /// 水平線（`---`・`***`・`___`）。
        case thematicBreak
        /// リンク・画像のブラケットテキスト（`[text]`・`![alt]`）。
        case linkText
        /// リンク・画像の括弧付き宛先（`(url)`）。
        case linkURL
    }

    public var range: TextSpan
    public var kind: Kind

    public init(range: TextSpan, kind: Kind) {
        self.range = range
        self.kind = kind
    }
}
