import Foundation
import SwiftMarkdownEditorCore

/// Continues a Markdown list when Enter is pressed inside a list item.
///
/// - On a non-empty item, inserting a newline carries the marker down
///   (incrementing the number for ordered lists, resetting task checkboxes to
///   unchecked).
/// - On an *empty* item (just the marker), Enter removes the marker and outdents
///   — the universal "press Enter twice to leave the list" behavior.
public struct ListContinuationRule: InputRule {

    public init() {}

    public func transform(
        state: EditorState,
        inserting text: String,
        replacing range: TextSpan
    ) -> RuleTransform? {
        // Only fires on a plain Enter at a caret.
        guard text == "\n", range.isEmpty else { return nil }
        let caret = range.lowerBound

        let lineRange = state.text.lineRange(containing: caret)
        let line = state.text.substring(in: lineRange)
        guard let prefix = ListPrefix.parse(line) else { return nil }

        let lineStart = lineRange.lowerBound
        let contentStartGlobal = lineStart + prefix.contentStart
        let contentEndGlobal = lineRange.upperBound

        let content = state.text.substring(in: TextSpan(lowerBound: contentStartGlobal, upperBound: contentEndGlobal))
        let isEmptyItem = content.trimmingCharacters(in: .whitespaces).isEmpty

        if isEmptyItem {
            // Exit the list: clear the marker on this line, place caret at line start.
            let change = TextChange(
                range: TextSpan(lowerBound: lineStart, upperBound: lineRange.upperBound),
                replacement: ""
            )
            return RuleTransform(change: change, selection: Selection(caret: lineStart))
        }

        // Continue the list: newline + the next marker.
        let nextMarker = prefix.nextMarker()
        let insertion = "\n" + nextMarker
        let change = TextChange(insert: insertion, at: caret)
        let caretAfter = caret + insertion.utf16Length
        return RuleTransform(change: change, selection: Selection(caret: caretAfter))
    }
}

/// The parsed leading marker of a list item line.
struct ListPrefix {

    enum Kind {
        case bullet(Character)            // -, *, +
        case ordered(number: Int, delimiter: Character) // 1. / 1)
    }

    var indentation: String
    var kind: Kind
    var hasCheckbox: Bool
    /// UTF-16 offset within the line where the item content begins.
    var contentStart: Int

    /// Builds the marker to start the next item (incremented / reset checkbox).
    func nextMarker() -> String {
        var marker = indentation
        switch kind {
        case .bullet(let ch):
            marker.append(ch)
        case .ordered(let number, let delimiter):
            marker += "\(number + 1)"
            marker.append(delimiter)
        }
        marker += " "
        if hasCheckbox { marker += "[ ] " }
        return marker
    }

    /// Parses a list marker at the start of `line`, or returns `nil`.
    static func parse(_ line: String) -> ListPrefix? {
        let u = Array(line.utf16)
        var i = 0

        // Indentation.
        while i < u.count && (u[i] == 0x20 || u[i] == 0x09) { i += 1 }
        let indentEnd = i
        guard i < u.count else { return nil }

        let c = u[i]
        var kind: Kind
        if c == 0x2D || c == 0x2A || c == 0x2B { // - * +
            // Must be followed by a space to be a list item.
            guard i + 1 < u.count, u[i + 1] == 0x20 else { return nil }
            kind = .bullet(Character(UnicodeScalar(c)!))
            i += 2
        } else if c >= 0x30 && c <= 0x39 { // digit
            var numEnd = i
            while numEnd < u.count && u[numEnd] >= 0x30 && u[numEnd] <= 0x39 { numEnd += 1 }
            guard numEnd < u.count, u[numEnd] == 0x2E || u[numEnd] == 0x29 else { return nil } // . or )
            let delimiterIndex = numEnd
            guard delimiterIndex + 1 < u.count, u[delimiterIndex + 1] == 0x20 else { return nil }
            let digits = u[i..<numEnd].map { Character(UnicodeScalar($0)!) }
            let number = Int(String(digits)) ?? 1
            kind = .ordered(number: number, delimiter: Character(UnicodeScalar(u[delimiterIndex])!))
            i = delimiterIndex + 2
        } else {
            return nil
        }

        // Optional task checkbox.
        var hasCheckbox = false
        if i + 3 <= u.count, u[i] == 0x5B, u[i + 2] == 0x5D { // [ _ ]
            let mid = u[i + 1]
            if mid == 0x20 || mid == 0x78 || mid == 0x58 { // space, x, X
                hasCheckbox = true
                i += 3
                if i < u.count && u[i] == 0x20 { i += 1 } // consume trailing space
            }
        }

        let indentation = String(decoding: Array(u[0..<indentEnd]), as: UTF16.self)
        return ListPrefix(indentation: indentation, kind: kind, hasCheckbox: hasCheckbox, contentStart: i)
    }
}
