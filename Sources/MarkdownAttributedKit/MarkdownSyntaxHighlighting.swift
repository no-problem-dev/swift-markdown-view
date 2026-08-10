import Foundation
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// Produces the syntax highlighting attributes for a string of code.
///
/// Real highlighters — Highlight.js through JavaScriptCore, for one — run off the main actor, hence the
/// asynchrony. Returning `nil` displays the code as plain text with no color. The result is a Foundation
/// `AttributedString`, which keeps this layer free of UI: only its foreground colors are transplanted
/// into the storage.
///
/// > Note: The client-facing API is the `SyntaxHighlighter` protocol, injected with the
/// > `.markdownSyntaxHighlighter(_:)` modifier. `MarkdownCodeHighlighting` is the low-level interface
/// > inside the rendering pipeline, and differs in returning an optional: `nil` means "leave the code
/// > uncolored", whereas a `SyntaxHighlighter` must always return a string.
package protocol MarkdownCodeHighlighting: Sendable {
    func highlightedCode(_ code: String, language: String?) async throws -> AttributedString?
}

/// A region of code inside the built attributed string.
///
/// Located by its ``NSAttributedString/Key/markdownCodeLanguage`` tag.
package struct MarkdownCodeRegion: Equatable {
    public let range: NSRange
    public let language: String?
    public let code: String
}

package enum MarkdownSyntaxHighlighting {

    /// Every code region in the document, in document order.
    ///
    /// A range covers the code text only, excluding the block separator, so a highlighter's output lines
    /// up with it one to one.
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

    /// Transplants the foreground colors of a highlighter's output into a range of the storage.
    ///
    /// Only colors are copied, so the monospaced font, the paragraph style, and the block decoration all
    /// survive.
    ///
    /// - Returns: `false` when the highlighted text is not the same length as the range — a highlighter
    ///   must return exactly the characters it was given — leaving the storage untouched.
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
