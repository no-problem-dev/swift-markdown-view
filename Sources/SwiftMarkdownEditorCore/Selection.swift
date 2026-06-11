import Foundation

/// A text selection: a range plus the side the caret is anchored to.
///
/// `anchor` is the fixed end (where selection started) and `head` is the moving
/// end (where the caret is). When `anchor == head` the selection is a caret.
/// Keeping the direction lets shift-extending a selection behave correctly and
/// lets input rules know which end to collapse to.
public struct Selection: Equatable, Hashable, Sendable {

    /// The fixed end of the selection (UTF-16 offset).
    public var anchor: Int

    /// The moving end of the selection where the caret sits (UTF-16 offset).
    public var head: Int

    public init(anchor: Int, head: Int) {
        precondition(anchor >= 0 && head >= 0, "selection offsets must be non-negative")
        self.anchor = anchor
        self.head = head
    }

    /// A caret (empty selection) at `offset`.
    public init(caret offset: Int) {
        self.init(anchor: offset, head: offset)
    }

    /// A selection spanning a ``TextSpan`` with the caret at its upper bound.
    public init(range: TextSpan) {
        self.init(anchor: range.lowerBound, head: range.upperBound)
    }

    /// Whether the selection is a single caret with no span.
    public var isCaret: Bool { anchor == head }

    /// The selection as an order-normalized ``TextSpan``.
    public var range: TextSpan {
        TextSpan(lowerBound: Swift.min(anchor, head), upperBound: Swift.max(anchor, head))
    }
}
