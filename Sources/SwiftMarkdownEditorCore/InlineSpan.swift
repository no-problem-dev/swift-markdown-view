import Foundation

/// マッチしたインラインスパン：スタイル適用対象のテキスト範囲と、それを生成したデリミタ（マーカー）範囲のペア。
///
/// Phase 1 の ``MarkdownToken`` スキャナはソースハイライト用にフラットなデリミタランを出力する。
/// ライブプレビューはさらに多くを必要とする：`**bold**` を **bold** としてレンダリングし `**` を隠すには、
/// *コンテンツ* 範囲（スタイル適用対象）と *マーカー* 範囲（非表示対象）の両方が必要。
/// ``InlineSpan`` はデリミタをペアにし、正確な UTF-16 オフセットを保持するため、
/// TextKit 層は再計測なしに属性を適用できる。
package struct InlineSpan: Equatable, Sendable {

    package enum Kind: Equatable, Hashable, Sendable {
        case strong          // **x** / __x__
        case emphasis        // *x* / _x_
        case strikethrough   // ~~x~~
        case code            // `x`
    }

    package var kind: Kind
    /// マーカーを含むスパン全体の範囲。
    package var fullRange: TextSpan
    /// マーカー間のコンテンツ範囲（スタイルが適用される部分）。
    package var contentRange: TextSpan
    /// デリミタ範囲（開きマーカー・閉じマーカーの順）— 非表示対象。
    package var markerRanges: [TextSpan]

    package init(kind: Kind, fullRange: TextSpan, contentRange: TextSpan, markerRanges: [TextSpan]) {
        self.kind = kind
        self.fullRange = fullRange
        self.contentRange = contentRange
        self.markerRanges = markerRanges
    }
}
