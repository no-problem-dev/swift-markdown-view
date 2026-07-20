import Foundation

package extension NSAttributedString.Key {
    /// 段落範囲をデコレーションブロックとしてマークし、TextKit レイアウトフラグメントが背景や装飾（コードブロック塗りつぶし、引用バー、水平線）を描画できるようにする。値は ``MarkdownBlockDecoration``。
    static let markdownBlockDecoration = NSAttributedString.Key("markdownBlockDecoration")

    /// コードブロックの言語文字列（未指定の場合は空文字）。コードの文字範囲をマークし、非同期シンタックスハイライターが初期レイアウト後に範囲を特定して再着色できるようにする。
    static let markdownCodeLanguage = NSAttributedString.Key("markdownCodeLanguage")

    /// リテラルテキスト以外として描画されるテキストラン（画像/数式アタッチメント、リストマーカー）の Markdown ソース。「Markdown としてコピー」コマンドで Markdown を再構築するために使用する。
    static let markdownSource = NSAttributedString.Key("markdownSource")

    /// アタッチメントラン（画像または数式）を ``MarkdownAttachment`` として識別し、非同期リゾルバーがレイアウト後に画像を埋めたり更新したりできるようにする。
    static let markdownAttachment = NSAttributedString.Key("markdownAttachment")

    /// ブロッククォート/aside のリーディングバーに使用する `PlatformColor`。パレットのデフォルトを上書きし、aside の種類に応じてバーを着色する。
    static let markdownDecorationBar = NSAttributedString.Key("markdownDecorationBar")
}

/// レンダリングテキスト内でアタッチメント文字（U+FFFC）1文字を占めるインラインオブジェクト（画像または数式）。選択が1文字として通過し、Copy-as-Markdown がソースを再構築できる。
public final class MarkdownAttachment: NSObject {

    public enum Kind: Equatable, Sendable {
        case image(source: String, alt: String)
        case inlineMath(latex: String)
        case displayMath(latex: String)
        /// Mermaid ダイアグラム。WebView アタッチメントとして描画する。
        case mermaid(source: String)
    }

    public let kind: Kind

    public init(_ kind: Kind) {
        self.kind = kind
    }

    public override func isEqual(_ object: Any?) -> Bool {
        (object as? MarkdownAttachment).map { $0.kind == kind } ?? false
    }

    public override var hash: Int {
        switch kind {
        case .image(let s, _): return s.hashValue
        case .inlineMath(let l), .displayMath(let l): return l.hashValue
        case .mermaid(let s): return s.hashValue
        }
    }
}

/// カスタムレイアウトフラグメントによってブロック範囲をどう装飾するかを記述する。参照型（`NSObject`）として `NSTextStorage` の属性値になり、コピー/編集操作でも生き残る。
package final class MarkdownBlockDecoration: NSObject {

    public enum Kind: Equatable, Sendable {
        /// フェンス/インデント形式のコードブロック。フラグメントが丸角背景を塗りつぶす。
        case codeBlock(language: String?)
        /// 指定ネスト深度のブロッククォート（1 = 最上位）。フラグメントが各レベルにリーディングバーを描画する。
        case blockQuote(level: Int)
        /// テーマティックブレーク。フラグメントが水平線を描画する。
        case thematicBreak
        /// テーブル。フラグメントがヘッダー下線と行区切りを描画する。
        case table(columns: Int)
    }

    public let kind: Kind

    public init(_ kind: Kind) {
        self.kind = kind
    }

    public override func isEqual(_ object: Any?) -> Bool {
        (object as? MarkdownBlockDecoration).map { $0.kind == kind } ?? false
    }

    public override var hash: Int {
        switch kind {
        case .codeBlock(let language): return language.hashValue
        case .blockQuote(let level): return level.hashValue
        case .thematicBreak: return 0x7B12EAC
        case .table(let columns): return 0x7AB1E ^ columns.hashValue
        }
    }
}
