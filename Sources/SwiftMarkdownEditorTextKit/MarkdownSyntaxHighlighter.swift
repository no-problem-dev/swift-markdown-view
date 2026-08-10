import Foundation
import SwiftMarkdownEditorCore

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// Turns syntax tokens into text attributes and applies them.
///
/// This is the one place a token kind becomes a color and a font. Keeping it out of the text view
/// leaves the attribute logic a pure, testable function: a test can build the attributed string with
/// no live view and inspect the color and font at any offset, and snapshots render that same string.
enum MarkdownSyntaxHighlighter {

    /// Builds the platform font for a set of traits.
    ///
    /// A monospace font is requested by weight, so `italic` has no effect alongside `monospace`.
    /// Falls back to the plain system font when the traits cannot be applied to the descriptor.
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

    /// The attributes for text that carries no token style. Also used as the typing attributes.
    static func baseAttributes(theme: MarkdownEditorTheme) -> [NSAttributedString.Key: Any] {
        [
            .font: font(size: theme.baseFontSize),
            .foregroundColor: theme.textColor
        ]
    }

    /// The attributes for a single token kind.
    ///
    /// A foreground color is included only when the style defines one, so a style with no color
    /// leaves the base text color showing through.
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

    /// Resets the storage to the base style, then applies the attributes of every token.
    ///
    /// Token offsets must be valid for the storage; a token reaching past its end is skipped rather
    /// than trapping. Where token ranges overlap, the later token's attributes win.
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

    /// Tokenizes the storage's own string and re-applies the highlighting in place.
    static func highlight(_ storage: NSMutableAttributedString, theme: MarkdownEditorTheme) {
        let tokens = MarkdownTokenizer.tokenize(storage.string)
        apply(tokens: tokens, to: storage, theme: theme)
    }

    /// Builds a highlighted attributed string for the given text.
    ///
    /// No text view is involved, so previews, snapshots, and tests can call it directly.
    static func attributedString(for text: String, theme: MarkdownEditorTheme) -> NSMutableAttributedString {
        let storage = NSMutableAttributedString(string: text)
        highlight(storage, theme: theme)
        return storage
    }
}
