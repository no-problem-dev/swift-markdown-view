import Foundation

/// How a position that lands exactly at an edit boundary is mapped.
///
/// Mirrors CodeMirror's `assoc`/ProseMirror's `bias`: when inserted text is
/// added at a position, a caret sitting on that position can either stay before
/// the insertion (`.left`) or move after it (`.right`). Typing should push the
/// caret to the right of what you just typed, so `.right` is the default.
public enum AssociationBias: Sendable {
    case left
    case right
}

/// A single atomic edit: replace `range` in the old text with `replacement`.
///
/// This is the editor's unit of change (CodeMirror's `ChangeSpec` /
/// ProseMirror's `ReplaceStep`). It is a pure value: it can be applied to a
/// string, used to map saved positions (carets, decorations) across the edit,
/// and inverted to support undo.
public struct TextChange: Equatable, Sendable {

    /// The range in the **old** text that is replaced (UTF-16 offsets).
    public var range: TextSpan

    /// The text inserted in place of `range`.
    public var replacement: String

    public init(range: TextSpan, replacement: String) {
        self.range = range
        self.replacement = replacement
    }

    /// Convenience: an insertion at a caret offset.
    public init(insert text: String, at offset: Int) {
        self.init(range: TextSpan(caret: offset), replacement: text)
    }

    /// The length of the inserted text in UTF-16 code units.
    public var insertedLength: Int { replacement.utf16Length }

    /// The signed change in total document length this edit produces.
    public var lengthDelta: Int { insertedLength - range.length }

    /// The range the replacement occupies in the **new** text.
    public var insertedRange: TextSpan {
        TextSpan(location: range.lowerBound, length: insertedLength)
    }

    // MARK: - Apply

    /// Returns `text` with this change applied.
    public func apply(to text: String) -> String {
        var result = text
        result.replaceSubrange(text.range(for: range), with: replacement)
        return result
    }

    // MARK: - Position mapping

    /// Maps an offset in the old text to the corresponding offset in the new text.
    ///
    /// - Positions before the edit are unchanged.
    /// - Positions after the edit shift by `lengthDelta`.
    /// - Positions strictly inside the replaced range collapse to the start
    ///   (`.left`) or the end of the insertion (`.right`).
    /// - A position exactly at the edit's start stays put for `.left` and moves
    ///   to the end of the insertion for `.right`.
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

    /// Maps a selection across this change, preserving direction.
    public func mapSelection(_ selection: Selection, bias: AssociationBias = .right) -> Selection {
        Selection(
            anchor: mapOffset(selection.anchor, bias: bias),
            head: mapOffset(selection.head, bias: bias)
        )
    }

    // MARK: - Invert

    /// Returns the inverse change that undoes this one.
    ///
    /// Requires the original text because the inverse must restore the bytes
    /// that were replaced.
    public func inverted(in oldText: String) -> TextChange {
        let replaced = oldText.substring(in: range)
        return TextChange(range: insertedRange, replacement: replaced)
    }
}
