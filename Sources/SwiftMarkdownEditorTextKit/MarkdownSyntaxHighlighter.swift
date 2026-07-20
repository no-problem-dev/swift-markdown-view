import Foundation
import SwiftMarkdownEditorCore

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// ``MarkdownToken`` をテキスト属性に変換して適用する。
///
/// トークン種別が色・フォントになる唯一の場所。テキストビューから分離することで
/// 属性ロジックが純粋でテスト可能な関数になる：
/// テストは実行中のビューなしで attributed string を構築して任意のオフセットの色・フォントを検証でき、
/// スナップショットも同じ文字列をレンダリングできる。
enum MarkdownSyntaxHighlighter {

    /// トレイトセットに対応するプラットフォームフォントを構築する。
    static func font(
        size: CGFloat,
        bold: Bool = false,
        italic: Bool = false,
        monospace: Bool = false
    ) -> PlatformFont {
        if monospace {
            let weight: PlatformFont.Weight = bold ? .semibold : .regular
            return PlatformFont.monospacedSystemFont(ofSize: size, weight: weight)
        }

        #if canImport(UIKit)
        var traits: UIFontDescriptor.SymbolicTraits = []
        if bold { traits.insert(.traitBold) }
        if italic { traits.insert(.traitItalic) }
        let base = UIFont.systemFont(ofSize: size)
        if traits.isEmpty { return base }
        if let descriptor = base.fontDescriptor.withSymbolicTraits(traits) {
            return UIFont(descriptor: descriptor, size: size)
        }
        return base
        #elseif canImport(AppKit)
        var traits: NSFontDescriptor.SymbolicTraits = []
        if bold { traits.insert(.bold) }
        if italic { traits.insert(.italic) }
        let base = NSFont.systemFont(ofSize: size)
        if traits.isEmpty { return base }
        let descriptor = base.fontDescriptor.withSymbolicTraits(traits)
        return NSFont(descriptor: descriptor, size: size) ?? base
        #endif
    }

    /// ベース（スタイルなし）のテキスト属性。
    static func baseAttributes(theme: MarkdownEditorTheme) -> [NSAttributedString.Key: Any] {
        [
            .font: font(size: theme.baseFontSize),
            .foregroundColor: theme.textColor
        ]
    }

    /// 1 つのトークン種別の属性。
    static func attributes(
        for kind: MarkdownToken.Kind,
        theme: MarkdownEditorTheme
    ) -> [NSAttributedString.Key: Any] {
        let style = theme.style(for: kind)
        var attrs: [NSAttributedString.Key: Any] = [
            .font: font(size: theme.baseFontSize, bold: style.bold, italic: style.italic, monospace: style.monospace)
        ]
        if let color = style.color {
            attrs[.foregroundColor] = color
        }
        if style.strikethrough {
            attrs[.strikethroughStyle] = NSUnderlineStyle.single.rawValue
        }
        return attrs
    }

    /// `storage` をベーススタイルにリセットしてからすべてのトークン属性を適用する。
    ///
    /// `tokens` のオフセットは `storage` に有効でなければならない。
    /// 範囲外のトークンは防御的にスキップする。
    static func apply(
        tokens: [MarkdownToken],
        to storage: NSMutableAttributedString,
        theme: MarkdownEditorTheme
    ) {
        let full = NSRange(location: 0, length: storage.length)
        storage.setAttributes(baseAttributes(theme: theme), range: full)
        for token in tokens {
            let range = token.range.nsRange
            guard range.location >= 0, NSMaxRange(range) <= storage.length else { continue }
            storage.addAttributes(attributes(for: token.kind, theme: theme), range: range)
        }
    }

    /// `storage` の文字列をトークナイズしてハイライトをインプレースで再適用する。
    static func highlight(_ storage: NSMutableAttributedString, theme: MarkdownEditorTheme) {
        let tokens = MarkdownTokenizer.tokenize(storage.string)
        apply(tokens: tokens, to: storage, theme: theme)
    }

    /// `text` のハイライト済み attributed string を構築する。
    ///
    /// プレビュー・スナップショット・テストに利用できる（テキストビュー不要）。
    static func attributedString(for text: String, theme: MarkdownEditorTheme) -> NSMutableAttributedString {
        let storage = NSMutableAttributedString(string: text)
        highlight(storage, theme: theme)
        return storage
    }
}
