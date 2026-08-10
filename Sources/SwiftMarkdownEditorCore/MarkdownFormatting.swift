import Foundation

/// A computed edit: the change to apply, and where the selection ends up afterwards.
public struct EditTransform: Equatable, Sendable {
    public var change: TextChange
    public var selection: Selection

    public init(change: TextChange, selection: Selection) {
        self.change = change
        self.selection = selection
    }
}

/// The formatting commands behind a toolbar or keyboard shortcut, written as pure functions.
///
/// Every command is a pure `(text, selection) -> EditTransform`, so the whole formatting
/// behaviour — wrapping, toggling, line prefixes, links — can be unit tested without a text view.
/// The TextKit layer only has to apply the resulting change to the platform text view, which is
/// what gives it native undo.
public enum MarkdownFormatting {

    /// Wraps the selection in a delimiter, or unwraps it when it is already wrapped.
    ///
    /// At a caret, it inserts the delimiter pair and leaves the caret between the two halves.
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

    /// Toggles a line prefix such as `# `, `> ` or `- ` on every line the selection touches.
    ///
    /// The prefix is removed when all of the affected lines already carry it, and added otherwise.
    public static func toggleLinePrefix(text: String, selection: Selection, prefix: String) -> EditTransform {
        let range = selection.range
        let blockStart = text.lineRange(containing: range.lowerBound).lowerBound
        let blockEnd = text.lineRange(containing: range.upperBound).upperBound
        let block = text.substring(in: TextSpan(lowerBound: blockStart, upperBound: blockEnd))

        let lines = block.components(separatedBy: "\n")
        // A single line is always toggled — even when blank, so a heading/quote/
        // list can be started on an empty line. In a multi-line block, blank lines
        // are left untouched (they aren't separators worth prefixing).
        let single = lines.count == 1
        let toggled = single ? lines : lines.filter { !$0.isEmpty }
        let allHavePrefix = !toggled.isEmpty && toggled.allSatisfy { $0.hasPrefix(prefix) }

        let newLines: [String]
        if allHavePrefix {
            newLines = lines.map { $0.hasPrefix(prefix) ? String($0.dropFirst(prefix.count)) : $0 }
        } else {
            newLines = lines.map { line in
                if line.hasPrefix(prefix) { return line }
                if line.isEmpty && !single { return line }
                return prefix + line
            }
        }
        let replacement = newLines.joined(separator: "\n")

        let change = TextChange(range: TextSpan(lowerBound: blockStart, upperBound: blockEnd), replacement: replacement)

        let newSelection: Selection
        if range.lowerBound == range.upperBound {
            // Collapsed caret: shift it by the prefix delta applied on its line so
            // typing continues naturally (after the inserted "# ", not over it).
            let prefixLength = prefix.utf16Length
            let caret = allHavePrefix
                ? Swift.max(blockStart, range.upperBound - prefixLength)
                : range.upperBound + prefixLength
            newSelection = Selection(caret: caret)
        } else {
            newSelection = Selection(anchor: blockStart, head: blockStart + replacement.utf16Length)
        }
        return EditTransform(change: change, selection: newSelection)
    }

    /// Turns the selection into a Markdown link and selects the URL placeholder.
    ///
    /// Leaving the placeholder selected means the user can type the destination straight away.
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
