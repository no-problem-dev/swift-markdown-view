import Foundation
import Testing
@testable import SwiftMarkdownEditorTextKit

/// 親がテキストを差し替えたときの選択保持の検証。
///
/// 以前は長さを無条件に 0 へ潰していたため、正規化・整形・外部 undo・再読込のたびに
/// ユーザーの選択が消えてキャレットになっていた。
@Suite("選択範囲のクランプ")
struct ClampSelectionTests {

    private func clamp(_ location: Int, _ length: Int, to total: Int) -> NSRange {
        MarkdownSourceTextView.clampSelection(NSRange(location: location, length: length), toLength: total)
    }

    @Test("収まる選択はそのまま保たれる")
    func fittingSelectionSurvives() {
        #expect(clamp(2, 3, to: 10) == NSRange(location: 2, length: 3))
    }

    @Test("末尾をはみ出す選択は長さだけ切り詰める")
    func overflowingSelectionIsTruncated() {
        #expect(clamp(8, 5, to: 10) == NSRange(location: 8, length: 2))
    }

    @Test("開始位置が範囲外なら末尾に寄せる")
    func locationBeyondEndClampsToEnd() {
        #expect(clamp(20, 3, to: 10) == NSRange(location: 10, length: 0))
    }

    @Test("キャレットはキャレットのまま")
    func caretStaysCaret() {
        #expect(clamp(4, 0, to: 10) == NSRange(location: 4, length: 0))
    }

    @Test("空のテキストでは先頭のキャレットになる")
    func emptyTextCollapsesToStart() {
        #expect(clamp(4, 2, to: 0) == NSRange(location: 0, length: 0))
    }

    @Test("ちょうど末尾までの選択は保たれる")
    func selectionToExactEndSurvives() {
        #expect(clamp(6, 4, to: 10) == NSRange(location: 6, length: 4))
    }
}
