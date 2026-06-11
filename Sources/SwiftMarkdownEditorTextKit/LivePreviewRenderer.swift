import Foundation
import SwiftMarkdownEditorCore

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// Applies live-preview styling to an `NSTextStorage`: content gets font traits,
/// and delimiter markers are concealed using the **clear color + tiny font +
/// negative kern** technique (verified against `nodes-app/swift-markdown-engine`'s
/// `MarkdownStyler`). The source text is never modified — only its attributes.
public enum LivePreviewRenderer {

    /// Tiny font size that collapses a concealed marker's glyphs to near-zero;
    /// the negative kern removes the residual advance. Matches
    /// `swift-markdown-engine`'s `hiddenMarkerFontSize` default (0.1).
    static let concealFontSize: CGFloat = 0.1

    /// Re-applies live-preview attributes for the whole document.
    public static func apply(
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

    // MARK: - Font trait merge

    /// Adds a symbolic trait to whatever font already covers `range`, so bold and
    /// italic compose (e.g. emphasis nested in strong becomes bold-italic).
    private static func mergeTrait(_ trait: EditorFontTrait, in range: NSRange, storage: NSTextStorage, baseSize: CGFloat) {
        storage.enumerateAttribute(.font, in: range, options: []) { value, subRange, _ in
            let base = (value as? PlatformFont) ?? MarkdownSyntaxHighlighter.font(size: baseSize)
            if let merged = base.addingEditorTrait(trait) {
                storage.addAttribute(.font, value: merged, range: subRange)
            }
        }
    }
}

/// Composable font traits for live-preview styling.
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
