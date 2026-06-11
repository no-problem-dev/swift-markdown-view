import Foundation
import Testing
import SwiftMarkdownEditorCore
@testable import SwiftMarkdownEditorTextKit

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

struct MarkdownSyntaxHighlighterTests {

    private let theme = MarkdownEditorTheme.light

    private func color(_ attr: NSAttributedString, at offset: Int) -> PlatformColor? {
        attr.attribute(.foregroundColor, at: offset, effectiveRange: nil) as? PlatformColor
    }

    private func font(_ attr: NSAttributedString, at offset: Int) -> PlatformFont? {
        attr.attribute(.font, at: offset, effectiveRange: nil) as? PlatformFont
    }

    private func isBold(_ font: PlatformFont?) -> Bool {
        guard let font else { return false }
        #if canImport(UIKit)
        return font.fontDescriptor.symbolicTraits.contains(.traitBold)
        #else
        return font.fontDescriptor.symbolicTraits.contains(.bold)
        #endif
    }

    private func isMonospace(_ font: PlatformFont?) -> Bool {
        // Monospaced system font has a fixed advance for distinct glyphs.
        guard let font else { return false }
        let attrs: [NSAttributedString.Key: Any] = [.font: font]
        let wide = ("W" as NSString).size(withAttributes: attrs).width
        let narrow = ("i" as NSString).size(withAttributes: attrs).width
        return abs(wide - narrow) < 0.5
    }

    @Test("Attributed string length matches source")
    func length() {
        let s = MarkdownSyntaxHighlighter.attributedString(for: "# Hello", theme: theme)
        #expect(s.length == 7)
    }

    @Test("Heading marker is tinted with the muted color")
    func headingMarkerColor() {
        let s = MarkdownSyntaxHighlighter.attributedString(for: "# Hi", theme: theme)
        let expected = theme.style(for: .headingMarker).color
        #expect(color(s, at: 0) == expected)
    }

    @Test("Heading text is bold")
    func headingTextBold() {
        let s = MarkdownSyntaxHighlighter.attributedString(for: "# Hi", theme: theme)
        // "Hi" starts at offset 2.
        #expect(isBold(font(s, at: 2)))
    }

    @Test("Inline code is monospaced")
    func inlineCodeMono() {
        let s = MarkdownSyntaxHighlighter.attributedString(for: "a `code` b", theme: theme)
        // The backtick is at offset 2.
        #expect(isMonospace(font(s, at: 2)))
    }

    @Test("Plain text uses the base color, not a token tint")
    func plainTextBaseColor() {
        let s = MarkdownSyntaxHighlighter.attributedString(for: "just text", theme: theme)
        #expect(color(s, at: 0) == theme.textColor)
        #expect(!isBold(font(s, at: 0)))
    }

    @Test("Strong delimiters are bold")
    func strongBold() {
        let s = MarkdownSyntaxHighlighter.attributedString(for: "x **b** y", theme: theme)
        // "**" starts at offset 2.
        #expect(isBold(font(s, at: 2)))
    }

    @Test("Applying out-of-range tokens is safe")
    func outOfRangeTokensIgnored() {
        let storage = NSMutableAttributedString(string: "abc")
        let tokens = [
            MarkdownToken(range: TextSpan(location: 0, length: 1), kind: .heading),
            MarkdownToken(range: TextSpan(location: 2, length: 100), kind: .strong) // out of range
        ]
        MarkdownSyntaxHighlighter.apply(tokens: tokens, to: storage, theme: theme)
        #expect(storage.length == 3) // unchanged, no crash
    }
}
