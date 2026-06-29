import Foundation
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// コード文字列のシンタックスハイライト属性を生成する内部プロトコル。
///
/// 実際のハイライター（例: JavaScriptCore 経由の Highlight.js）はメインアクター外で動くため非同期。
/// `nil` を返した場合、コードはカラー書式なしのプレーンテキストとして表示する。
/// UI 非依存: 結果は Foundation の `AttributedString` で、前景色をストレージに移植する。
///
/// > Note: ユーザー向けの公開 API は ``SyntaxHighlighter`` プロトコルを使用すること。
/// > `MarkdownCodeHighlighting` はレンダリングパイプライン内部の低レベルインタフェースであり、
/// > `throws` なし・`Optional` 返り値という制約を持つ。`SyntaxHighlighter` は `throws` に対応し、
/// > `.syntaxHighlighter(_:)` モディファイア経由で注入する。
public protocol MarkdownCodeHighlighting: Sendable {
    func highlightedCode(_ code: String, language: String?) async -> AttributedString?
}

/// 構築済み属性文字列内で ``NSAttributedString/Key/markdownCodeLanguage`` タグによって特定されるコード領域。
public struct MarkdownCodeRegion: Equatable {
    public let range: NSRange
    public let language: String?
    public let code: String
}

public enum MarkdownSyntaxHighlighting {

    /// ドキュメント順にすべてのコード領域を返す。範囲はコードテキストのみ（ブロック区切りを含まない）のため、ハイライターの出力が 1:1 で対応する。
    public static func regions(in attributed: NSAttributedString) -> [MarkdownCodeRegion] {
        var result: [MarkdownCodeRegion] = []
        let full = NSRange(location: 0, length: attributed.length)
        let string = attributed.string as NSString
        attributed.enumerateAttribute(.markdownCodeLanguage, in: full) { value, range, _ in
            guard let language = value as? String, range.length > 0 else { return }
            result.append(MarkdownCodeRegion(
                range: range,
                language: language.isEmpty ? nil : language,
                code: string.substring(with: range)
            ))
        }
        return result
    }

    /// ハイライター生成の `AttributedString` から前景色を `storage` の `range` に移植し、等幅フォント・段落スタイル・ブロックデコレーションを保持する。文字数不一致の場合は何もしない（ハイライターは同一文字を返さなければならない）。
    @discardableResult
    public static func applyForegroundColors(
        from highlighted: AttributedString,
        to storage: NSTextStorage,
        at range: NSRange
    ) -> Bool {
        let ns = NSAttributedString(highlighted)
        guard ns.length == range.length, NSMaxRange(range) <= storage.length else { return false }
        ns.enumerateAttribute(.foregroundColor, in: NSRange(location: 0, length: ns.length)) { value, sub, _ in
            guard let color = value else { return }
            storage.addAttribute(
                .foregroundColor,
                value: color,
                range: NSRange(location: range.location + sub.location, length: sub.length)
            )
        }
        return true
    }
}
