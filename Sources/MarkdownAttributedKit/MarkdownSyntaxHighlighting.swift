import Foundation
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// Produces syntax-highlighted attributes for a code string. Async because real
/// highlighters (e.g. Highlight.js via JavaScriptCore) are off the main actor.
/// Returns `nil` to leave the code as-is. UI-free: the result is a Foundation
/// `AttributedString` whose foreground colors are transplanted onto the storage.
public protocol MarkdownCodeHighlighting: Sendable {
    func highlightedCode(_ code: String, language: String?) async -> AttributedString?
}

/// A code region located in a built attributed string by its
/// ``NSAttributedString/Key/markdownCodeLanguage`` tag.
public struct MarkdownCodeRegion: Equatable {
    public let range: NSRange
    public let language: String?
    public let code: String
}

public enum MarkdownSyntaxHighlighting {

    /// All code regions in document order. The range covers only the code text
    /// (not the block separator), so a highlighter's output aligns 1:1.
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

    /// Transplants the foreground colors from a highlighter's `AttributedString`
    /// onto `storage` at `range`, preserving the monospaced font, paragraph
    /// style, and block decoration already there. No-op on a length mismatch
    /// (the highlighter must return the same characters).
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
