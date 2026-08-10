import Foundation

/// Which way a position sitting on the boundary of an edit is mapped.
///
/// The equivalent of CodeMirror's `assoc` and ProseMirror's `bias`. When text is inserted
/// at a position, a caret at that exact position either stays before the insertion
/// (`.left`) or moves after it (`.right`). Typing uses `.right`, the default, so the caret
/// is pushed along to the right of what was just typed.
public enum AssociationBias: Sendable {
    case left
    case right
}

/// A single atomic edit: one range of the old text, replaced by a new string.
///
/// This is the editor's unit of change, in the vein of CodeMirror's `ChangeSpec` and
/// ProseMirror's `ReplaceStep`. Being a pure value, it can be applied to a string, used to
/// map stored positions such as carets and decorations across the edit, and inverted for
/// undo.
public struct TextChange: Equatable, Sendable {

    /// The range being replaced, in UTF-16 offsets into the text **before** the edit.
    public var range: TextSpan

    /// The text that takes the place of the replaced range.
    public var replacement: String

    public init(range: TextSpan, replacement: String) {
        self.range = range
        self.replacement = replacement
    }

    /// Creates an insertion at a caret offset.
    public init(insert text: String, at offset: Int) {
        self.init(range: TextSpan(caret: offset), replacement: text)
    }

    /// The length of the replacement text, in UTF-16 code units.
    public var insertedLength: Int { replacement.utf16Length }

    /// The signed change in document length this edit produces.
    public var lengthDelta: Int { insertedLength - range.length }

    /// The range the replacement occupies in the text **after** the edit.
    public var insertedRange: TextSpan {
        TextSpan(location: range.lowerBound, length: insertedLength)
    }

    // MARK: - Alignment

    /// Returns this change with its range widened to the character boundaries of the text.
    ///
    /// When the range lands in the middle of a grapheme cluster, ``apply(to:)`` widens it to
    /// the enclosing boundaries before replacing, while ``lengthDelta`` and
    /// ``insertedRange`` keep reporting the original, narrower range — so the two disagree.
    /// Put a change through this before reading `lengthDelta` whenever its offsets were
    /// assembled by arithmetic. Selections that come from `UITextView` or `NSTextView` are
    /// already aligned, so this leaves them untouched.
    public func aligned(in text: String) -> TextChange {
        let alignedRange = text.alignedSpan(range)
        guard alignedRange != range else { return self }
        return TextChange(range: alignedRange, replacement: replacement)
    }

    // MARK: - Apply

    /// Returns the text with this change applied.
    public func apply(to text: String) -> String {
        var result = text
        result.replaceSubrange(text.range(for: range), with: replacement)
        return result
    }

    // MARK: - Position mapping

    /// Maps an offset in the old text to the matching offset in the new text.
    ///
    /// - Positions before the edit are unchanged.
    /// - Positions after the edit shift by `lengthDelta`.
    /// - Positions inside the replaced range collapse to the start of the insertion
    ///   (`.left`) or to its end (`.right`).
    /// - Both bounds of the range count as inside. A position exactly at the start of the
    ///   edit therefore stays put with `.left` and moves to the end of the insertion with
    ///   `.right`.
    public func mapOffset(_ offset: Int, bias: AssociationBias = .right) -> Int {
        if offset < range.lowerBound { return offset }
        if offset > range.upperBound { return offset + lengthDelta }
        // offset is within [lowerBound, upperBound]
        switch bias {
        case .left:
            return range.lowerBound
        case .right:
            return range.lowerBound + insertedLength
        }
    }

    /// Maps a selection across this change, preserving its direction.
    public func mapSelection(_ selection: Selection, bias: AssociationBias = .right) -> Selection {
        Selection(
            anchor: mapOffset(selection.anchor, bias: bias),
            head: mapOffset(selection.head, bias: bias)
        )
    }

    // MARK: - Invert

    /// Returns the change that undoes this one.
    ///
    /// The original text has to be supplied because the inverse must restore the exact
    /// characters that were replaced.
    public func inverted(in oldText: String) -> TextChange {
        let replaced = oldText.substring(in: range)
        return TextChange(range: insertedRange, replacement: replaced)
    }
}
