import Foundation
import Testing
import SwiftMarkdownEditorCore
@testable import SwiftMarkdownEditorTextKit

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// Verifies live-preview rendering at the attribute level — no simulator.
/// Applies ``LivePreviewRenderer`` to an `NSTextStorage` and asserts the conceal
/// technique (clear color + tiny font + negative kern) and font traits.
struct LivePreviewRendererTests {

    private let theme = MarkdownEditorTheme.light

    private func render(_ text: String, selection: Selection?, focused: Bool) -> NSTextStorage {
        let storage = NSTextStorage(string: text)
        LivePreviewRenderer.apply(text: text, selection: selection, focused: focused, to: storage, theme: theme)
        return storage
    }

    private func font(_ s: NSTextStorage, _ offset: Int) -> PlatformFont? {
        s.attribute(.font, at: offset, effectiveRange: nil) as? PlatformFont
    }

    private func color(_ s: NSTextStorage, _ offset: Int) -> PlatformColor? {
        s.attribute(.foregroundColor, at: offset, effectiveRange: nil) as? PlatformColor
    }

    private func isConcealed(_ s: NSTextStorage, _ offset: Int) -> Bool {
        // The conceal technique uses the tiny font size; that's the unambiguous signal.
        guard let f = font(s, offset) else { return false }
        return abs(f.pointSize - LivePreviewRenderer.concealFontSize) < 0.001
    }

    private func isBold(_ font: PlatformFont?) -> Bool {
        guard let font else { return false }
        #if canImport(UIKit)
        return font.fontDescriptor.symbolicTraits.contains(.traitBold)
        #else
        return font.fontDescriptor.symbolicTraits.contains(.bold)
        #endif
    }

    private func isMono(_ font: PlatformFont?) -> Bool {
        guard let font else { return false }
        let attrs: [NSAttributedString.Key: Any] = [.font: font]
        let wide = ("W" as NSString).size(withAttributes: attrs).width
        let narrow = ("i" as NSString).size(withAttributes: attrs).width
        return abs(wide - narrow) < 0.5
    }

    // MARK: - Conceal (unfocused)

    @Test("Strong markers are concealed, content is bold")
    func strongConcealed() {
        // "x **b** y" — ** at [2,4) and [5,7); "b" at 4.
        let s = render("x **b** y", selection: nil, focused: false)
        #expect(isConcealed(s, 2))         // first *
        #expect(isConcealed(s, 3))         // second *
        #expect(isConcealed(s, 5))         // closing **
        #expect(isBold(font(s, 4)))        // content "b"
        #expect(!isConcealed(s, 4))        // content not concealed
    }

    @Test("Concealed markers use a clear (alpha 0) foreground")
    func concealClearColor() {
        let s = render("x **b** y", selection: nil, focused: false)
        let c = color(s, 2)
        #expect(c != nil)
        #expect(c?.cgColor.alpha == 0)
    }

    @Test("Concealed markers carry a negative kern")
    func concealNegativeKern() {
        let s = render("x **b** y", selection: nil, focused: false)
        let kern = s.attribute(.kern, at: 2, effectiveRange: nil) as? CGFloat
        #expect(kern != nil)
        #expect((kern ?? 0) <= 0)
    }

    @Test("Emphasis content is italic")
    func emphasisItalic() {
        // "a *i* b" — "i" at offset 3.
        let s = render("a *i* b", selection: nil, focused: false)
        #expect(isConcealed(s, 2))
        let f = font(s, 3)
        #if canImport(UIKit)
        #expect(f?.fontDescriptor.symbolicTraits.contains(.traitItalic) == true)
        #else
        #expect(f?.fontDescriptor.symbolicTraits.contains(.italic) == true)
        #endif
    }

    @Test("Code content is monospaced")
    func codeMono() {
        // "a `c` b" — "c" at offset 3.
        let s = render("a `c` b", selection: nil, focused: false)
        #expect(isConcealed(s, 2))         // backtick
        #expect(isMono(font(s, 3)))
    }

    @Test("Strikethrough content has the strikethrough attribute")
    func strikethrough() {
        // "~~s~~" — "s" at offset 2.
        let s = render("~~s~~", selection: nil, focused: false)
        let style = s.attribute(.strikethroughStyle, at: 2, effectiveRange: nil) as? Int
        #expect(style == NSUnderlineStyle.single.rawValue)
    }

    @Test("Bold + italic compose (strong containing emphasis)")
    func boldItalicCompose() {
        // "**a *b* c**" — inner "b". Find offset of 'b'.
        let text = "**a *b* c**"
        let s = render(text, selection: nil, focused: false)
        let bIndex = (text as NSString).range(of: "b").location
        let f = font(s, bIndex)
        #expect(isBold(f))
        #if canImport(UIKit)
        #expect(f?.fontDescriptor.symbolicTraits.contains(.traitItalic) == true)
        #else
        #expect(f?.fontDescriptor.symbolicTraits.contains(.italic) == true)
        #endif
    }

    // MARK: - Reveal (focused, caret on the line)

    @Test("Caret on the line reveals raw markers (not concealed)")
    func revealOnCaretLine() {
        // Two lines; caret on line 1 (offset 1, inside "**b**").
        let text = "**b** x\nsecond"
        let s = render(text, selection: Selection(caret: 1), focused: true)
        #expect(!isConcealed(s, 0))        // first * is shown
        #expect(isBold(font(s, 2)))        // content "b" still bold
    }

    @Test("Caret on another line keeps this line's markers concealed")
    func concealOnOtherLine() {
        let text = "**b** x\nsecond"
        // caret on line 2 (offset 9).
        let s = render(text, selection: Selection(caret: 9), focused: true)
        #expect(isConcealed(s, 0))         // line 1 markers stay hidden
    }
}
