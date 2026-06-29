import Foundation

/// テキストバッファ上の範囲を **UTF-16 コードユニットオフセット** で表す。
///
/// オフセットは UTF-16 コードユニット（`Character` でも Unicode スカラでもない）であるため、
/// この UI 非依存層で生成した範囲が `NSAttributedString`・`NSRange`・
/// `UITextView`/`NSTextView` のセレクション API に TextKit 層で再計測なしに直接マッピングできる。
///
/// 権威あるエディタのドキュメントモデル規約
/// （CodeMirror の `EditorState`・ProseMirror の整数位置）を踏襲する。
/// 位置はバッファへの単純な整数オフセットのため、セレクションとデコレーションの計算が単純な算術になる。
public struct TextSpan: Equatable, Hashable, Sendable {

    /// 含む側の開始オフセット（UTF-16 コードユニット）。
    public var lowerBound: Int

    /// 含まない側の終了オフセット（UTF-16 コードユニット）。
    public var upperBound: Int

    /// 明示的な境界値から範囲を作成する。
    ///
    /// - Precondition: `lowerBound <= upperBound` かつ両者が非負。
    public init(lowerBound: Int, upperBound: Int) {
        precondition(lowerBound >= 0, "lowerBound must be non-negative")
        precondition(lowerBound <= upperBound, "lowerBound must not exceed upperBound")
        self.lowerBound = lowerBound
        self.upperBound = upperBound
    }

    /// 位置と長さから範囲を作成する（NSRange スタイル）。
    public init(location: Int, length: Int) {
        self.init(lowerBound: location, upperBound: location + length)
    }

    /// 指定オフセット位置の空（キャレット）範囲を作成する。
    public init(caret offset: Int) {
        self.init(lowerBound: offset, upperBound: offset)
    }

    /// 範囲の長さ（UTF-16 コードユニット数）。
    public var length: Int { upperBound - lowerBound }

    /// 範囲が空（キャレット位置）かどうか。
    public var isEmpty: Bool { lowerBound == upperBound }

    /// `offset` が `[lowerBound, upperBound)` 内に収まるかどうか。
    public func contains(_ offset: Int) -> Bool {
        offset >= lowerBound && offset < upperBound
    }

    /// この範囲が `other` と共有するオフセットを持つかどうか。
    ///
    /// 2 つの空範囲、または空範囲と非空範囲が接する場合は、
    /// キャレットが相手の範囲の厳密な内部にあるか境界を共有するときだけ重複とみなす。
    /// これはライブプレビューのカーソル対応「表示」に使う述語のため、
    /// 境界の接触はカウントされなければならない。
    public func overlaps(_ other: TextSpan) -> Bool {
        lowerBound <= other.upperBound && other.lowerBound <= upperBound
    }
}

public extension TextSpan {

    /// TextKit 層で使用するために Foundation の `NSRange` へ変換する。
    var nsRange: NSRange { NSRange(location: lowerBound, length: length) }

    /// Foundation の `NSRange` から範囲を作成する。
    init(_ nsRange: NSRange) {
        self.init(location: nsRange.location, length: nsRange.length)
    }
}
