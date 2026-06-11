import Foundation
import SwiftMarkdownEditorCore

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// Turns ``MarkdownToken``s into text attributes and applies them.
///
/// This is the only place token kinds become colors/fonts. It is split from the
/// text view so the attribute logic is a pure, testable function: tests can
/// build an attributed string and assert the color/font at any offset without a
/// running view, and snapshots can render the same string.
public enum MarkdownSyntaxHighlighter {

    /// Builds the platform font for a set of traits.
    public static func font(
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

    /// The base (unstyled) text attributes.
    public static func baseAttributes(theme: MarkdownEditorTheme) -> [NSAttributedString.Key: Any] {
        [
            .font: font(size: theme.baseFontSize),
            .foregroundColor: theme.textColor
        ]
    }

    /// The attributes for one token kind.
    public static func attributes(
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

    /// Resets `storage` to the base style, then applies all token attributes.
    ///
    /// `tokens` must be valid offsets into `storage`; out-of-bounds tokens are
    /// skipped defensively.
    public static func apply(
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

    /// Tokenizes `storage`'s string and re-applies highlighting in place.
    public static func highlight(_ storage: NSMutableAttributedString, theme: MarkdownEditorTheme) {
        let tokens = MarkdownTokenizer.tokenize(storage.string)
        apply(tokens: tokens, to: storage, theme: theme)
    }

    /// Builds a fully highlighted attributed string for `text`.
    ///
    /// Useful for previews, snapshots, and tests — no text view required.
    public static func attributedString(for text: String, theme: MarkdownEditorTheme) -> NSMutableAttributedString {
        let storage = NSMutableAttributedString(string: text)
        highlight(storage, theme: theme)
        return storage
    }
}
