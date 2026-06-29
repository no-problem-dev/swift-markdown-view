import Foundation

/// テキストセレクション：範囲とキャレットのアンカー方向を持つ。
///
/// `anchor` は固定端（セレクション開始位置）、`head` は移動端（キャレット位置）。
/// `anchor == head` のときセレクションはキャレット（空範囲）になる。
/// 方向を保持することで Shift 拡張が正しく動作し、入力ルールがどちら端に折り畳むかを把握できる。
public struct Selection: Equatable, Hashable, Sendable {

    /// セレクションの固定端（UTF-16 オフセット）。
    public var anchor: Int

    /// キャレットが位置するセレクションの移動端（UTF-16 オフセット）。
    public var head: Int

    public init(anchor: Int, head: Int) {
        precondition(anchor >= 0 && head >= 0, "selection offsets must be non-negative")
        self.anchor = anchor
        self.head = head
    }

    /// `offset` 位置のキャレット（空セレクション）を作成する。
    public init(caret offset: Int) {
        self.init(anchor: offset, head: offset)
    }

    /// ``TextSpan`` を範囲とし、キャレットをその上限に置くセレクションを作成する。
    public init(range: TextSpan) {
        self.init(anchor: range.lowerBound, head: range.upperBound)
    }

    /// セレクションがスパンを持たない単一キャレットかどうか。
    public var isCaret: Bool { anchor == head }

    /// 順序正規化された ``TextSpan`` としてのセレクション。
    public var range: TextSpan {
        TextSpan(lowerBound: Swift.min(anchor, head), upperBound: Swift.max(anchor, head))
    }
}
