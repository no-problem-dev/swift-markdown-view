import Foundation

/// A text selection: a range together with the direction it was made in.
///
/// `anchor` is the fixed end, where the selection started; `head` is the moving end, where
/// the caret sits. When the two are equal the selection is a caret — an empty range.
/// Carrying the direction is what makes shift-extension behave correctly and lets input
/// rules know which end to collapse to.
public struct Selection: Equatable, Hashable, Sendable {

    /// The fixed end of the selection, as a UTF-16 offset.
    public var anchor: Int

    /// The moving end of the selection, where the caret sits, as a UTF-16 offset.
    public var head: Int

    public init(anchor: Int, head: Int) {
        precondition(anchor >= 0 && head >= 0, "selection offsets must be non-negative")
        self.anchor = anchor
        self.head = head
    }

    /// Creates an empty selection — a caret — at the given offset.
    public init(caret offset: Int) {
        self.init(anchor: offset, head: offset)
    }

    /// Creates a selection covering the given span, with the caret at its upper bound.
    public init(range: TextSpan) {
        self.init(anchor: range.lowerBound, head: range.upperBound)
    }

    /// Whether the selection is a single caret rather than a span of text.
    public var isCaret: Bool { anchor == head }

    /// The selection as a span, with its two ends put in ascending order.
    public var range: TextSpan {
        TextSpan(lowerBound: Swift.min(anchor, head), upperBound: Swift.max(anchor, head))
    }
}
