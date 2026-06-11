import Foundation

/// A computed edit: the change to apply plus the resulting selection.
public struct EditTransform: Equatable, Sendable {
    public var change: TextChange
    public var selection: Selection

    public init(change: TextChange, selection: Selection) {
        self.change = change
        self.selection = selection
    }
}

/// Pure toolbar/keyboard formatting commands.
///
/// Each command is a pure function `(text, selection) -> EditTransform`, so the
/// entire formatting behavior (wrap, toggle, line prefixes, links) is unit
/// tested without a text view. The TextKit layer just applies the resulting
/// change to the platform text view (which gives native undo).
public enum MarkdownFormatting {

    /// Wraps the selection with `delimiter`, or unwraps it if already wrapped.
    ///
    /// At a caret, inserts a delimiter pair and places the caret between them.
    public static func wrap(text: String, selection: Selection, delimiter: String) -> EditTransform {
        let range = selection.range
        let delimLen = delimiter.utf16Length

        if range.isEmpty {
            let replacement = delimiter + delimiter
            let change = TextChange(range: range, replacement: replacement)
            let caret = range.lowerBound + delimLen
            return EditTransform(change: change, selection: Selection(caret: caret))
        }

        let selected = text.substring(in: range)

        // Toggle off when the selection is already wrapped in this delimiter.
        if selected.utf16Length >= 2 * delimLen,
           selected.hasPrefix(delimiter),
           selected.hasSuffix(delimiter) {
            let innerStart = selected.index(selected.startIndex, offsetBy: delimiter.count)
            let innerEnd = selected.index(selected.endIndex, offsetBy: -delimiter.count)
            let inner = String(selected[innerStart..<innerEnd])
            let change = TextChange(range: range, replacement: inner)
            let selection = Selection(
                anchor: range.lowerBound,
                head: range.lowerBound + inner.utf16Length
            )
            return EditTransform(change: change, selection: selection)
        }

        let replacement = delimiter + selected + delimiter
        let change = TextChange(range: range, replacement: replacement)
        let innerStart = range.lowerBound + delimLen
        let selection = Selection(anchor: innerStart, head: innerStart + selected.utf16Length)
        return EditTransform(change: change, selection: selection)
    }

    /// Toggles a line prefix (`# `, `> `, `- `) on every line the selection
    /// touches. If all touched lines already have the prefix, it is removed.
    public static func toggleLinePrefix(text: String, selection: Selection, prefix: String) -> EditTransform {
        let range = selection.range
        let blockStart = text.lineRange(containing: range.lowerBound).lowerBound
        let blockEnd = text.lineRange(containing: range.upperBound).upperBound
        let block = text.substring(in: TextSpan(lowerBound: blockStart, upperBound: blockEnd))

        let lines = block.components(separatedBy: "\n")
        let allHavePrefix = lines.allSatisfy { $0.hasPrefix(prefix) || $0.isEmpty }

        let newLines: [String]
        if allHavePrefix {
            newLines = lines.map { $0.hasPrefix(prefix) ? String($0.dropFirst(prefix.count)) : $0 }
        } else {
            newLines = lines.map { $0.hasPrefix(prefix) || $0.isEmpty ? $0 : prefix + $0 }
        }
        let replacement = newLines.joined(separator: "\n")

        let change = TextChange(range: TextSpan(lowerBound: blockStart, upperBound: blockEnd), replacement: replacement)
        let selection = Selection(anchor: blockStart, head: blockStart + replacement.utf16Length)
        return EditTransform(change: change, selection: selection)
    }

    /// Inserts a Markdown link around the selection, selecting the `url`
    /// placeholder so the user can type the destination.
    public static func insertLink(text: String, selection: Selection, urlPlaceholder: String = "url") -> EditTransform {
        let range = selection.range
        let selected = text.substring(in: range)
        let replacement = "[\(selected)](\(urlPlaceholder))"
        let change = TextChange(range: range, replacement: replacement)

        // [ + selected + ]( = 3 + selected, then the url placeholder.
        let urlStart = range.lowerBound + 3 + selected.utf16Length
        let selection = Selection(anchor: urlStart, head: urlStart + urlPlaceholder.utf16Length)
        return EditTransform(change: change, selection: selection)
    }
}
