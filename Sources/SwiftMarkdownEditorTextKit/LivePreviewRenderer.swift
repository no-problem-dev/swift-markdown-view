import Foundation
import SwiftMarkdownEditorCore

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// Applies live preview styling to a text storage, hiding the Markdown delimiters in place.
///
/// Content picks up font traits; markers are hidden with a clear foreground color, a near-zero font
/// size, and negative kerning to cancel the advance the shrunken glyphs would still occupy. Only
/// attributes change — the source text is left exactly as it is.
enum LivePreviewRenderer {

    /// The font size that shrinks a hidden marker's glyphs to almost nothing.
    ///
    /// The advance those shrunken glyphs still occupy is cancelled by the negative kerning applied
    /// alongside this size.
    static let concealFontSize: CGFloat = 0.1

    /// Re-applies the live preview attributes across the whole document.
    ///
    /// Markers stay hidden on every line except the ones the selection touches, and passing
    /// `focused: false` hides them everywhere. Runs reaching past the end of the storage are skipped.
    static func apply(
        text: String,
        selection: Selection?,
        focused: Bool,
        to storage: NSTextStorage,
        theme: MarkdownEditorTheme
    ) {
        let full = NSRange(location: 0, length: storage.length)
        storage.setAttributes(MarkdownSyntaxHighlighter.baseAttributes(theme: theme), range: full)

        let runs = LivePreviewStyler.runs(text: text, selection: selection, focused: focused)
        guard !runs.isEmpty else { return }

        let ns = text as NSString
        let concealFont = MarkdownSyntaxHighlighter.font(size: concealFontSize)
        let codeColor = theme.style(for: .inlineCode).color ?? theme.textColor

        for run in runs {
            let r = run.range.nsRange
            guard r.location >= 0, NSMaxRange(r) <= storage.length else { continue }

            switch run.trait {
            case .bold:
                mergeTrait(.bold, in: r, storage: storage, baseSize: theme.baseFontSize)
            case .italic:
                mergeTrait(.italic, in: r, storage: storage, baseSize: theme.baseFontSize)
            case .monospace:
                storage.addAttribute(.font, value: MarkdownSyntaxHighlighter.font(size: theme.baseFontSize, monospace: true), range: r)
                storage.addAttribute(.foregroundColor, value: codeColor, range: r)
            case .strikethrough:
                storage.addAttribute(.strikethroughStyle, value: NSUnderlineStyle.single.rawValue, range: r)
            case .heading(let level):
                let size = headingSize(level: level, base: theme.baseFontSize)
                storage.addAttribute(.font, value: MarkdownSyntaxHighlighter.font(size: size, bold: true), range: r)
                if let color = theme.style(for: .heading).color {
                    storage.addAttribute(.foregroundColor, value: color, range: r)
                }
            case .conceal:
                let markerText = ns.substring(with: r) as NSString
                let width = markerText.size(withAttributes: [.font: concealFont]).width
                storage.addAttributes([
                    .font: concealFont,
                    .foregroundColor: PlatformColor.clear,
                    .kern: -width,
                ], range: r)
            }
        }
    }

    // MARK: - Heading sizing

    /// The point size of an ATX heading, scaled from the base font size.
    ///
    /// Levels 1 through 5 step down in size; level 6 and any level out of range render at the base
    /// size.
    static func headingSize(level: Int, base: CGFloat) -> CGFloat {
        switch level {
        case 1: return base * 1.7
        case 2: return base * 1.45
        case 3: return base * 1.28
        case 4: return base * 1.15
        case 5: return base * 1.07
        default: return base * 1.0
        }
    }

    // MARK: - Font trait merge

    /// Adds a symbolic trait to every font already covering the range, so traits compose.
    ///
    /// Emphasis nested inside a strong span ends up bold-italic instead of replacing the bold.
    private static func mergeTrait(_ trait: EditorFontTrait, in range: NSRange, storage: NSTextStorage, baseSize: CGFloat) {
        storage.enumerateAttribute(.font, in: range, options: []) { value, subRange, _ in
            let base = (value as? PlatformFont) ?? MarkdownSyntaxHighlighter.font(size: baseSize)
            if let merged = base.addingEditorTrait(trait) {
                storage.addAttribute(.font, value: merged, range: subRange)
            }
        }
    }
}

/// A font trait that live preview styling composes onto whatever font is already in place.
enum EditorFontTrait { case bold, italic }

private extension PlatformFont {
    func addingEditorTrait(_ trait: EditorFontTrait) -> PlatformFont? {
        #if canImport(UIKit)
        var traits = fontDescriptor.symbolicTraits
        switch trait {
        case .bold: traits.insert(.traitBold)
        case .italic: traits.insert(.traitItalic)
        }
        guard let descriptor = fontDescriptor.withSymbolicTraits(traits) else { return nil }
        return UIFont(descriptor: descriptor, size: pointSize)
        #elseif canImport(AppKit)
        var traits = fontDescriptor.symbolicTraits
        switch trait {
        case .bold: traits.insert(.bold)
        case .italic: traits.insert(.italic)
        }
        let descriptor = fontDescriptor.withSymbolicTraits(traits)
        return NSFont(descriptor: descriptor, size: pointSize)
        #endif
    }
}
