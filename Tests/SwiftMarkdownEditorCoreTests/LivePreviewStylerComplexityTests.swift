import Foundation
import Testing
@testable import SwiftMarkdownEditorCore

/// ライブプレビューのスタイル計算が文書長に対して線形に留まることの検証。
///
/// この経路は打鍵ごと・カーソル移動ごとに `@MainActor` 上で走る。二次に膨らむと
/// UI がそのまま固まるため、機能の欠陥として現れる。
///
/// 時間ではなく**倍率**で判定する。線形なら入力 2 倍で時間も約 2 倍、二次なら約 4 倍。
@Suite("ライブプレビューが線形時間で走る")
struct LivePreviewStylerComplexityTests {

    private func document(lines: Int) -> String {
        String(repeating: "some **bold** and *it* text here\n", count: lines)
    }

    private func seconds(_ text: String) -> Double {
        let start = DispatchTime.now().uptimeNanoseconds
        _ = LivePreviewStyler.runs(text: text, selection: nil, focused: false)
        return Double(DispatchTime.now().uptimeNanoseconds - start) / 1_000_000_000
    }

    @Test("行数を 2 倍にしても所要時間は 2 倍前後に留まる")
    func stylerStaysLinear() {
        _ = seconds(document(lines: 800))          // 暖機
        let small = seconds(document(lines: 800))
        let large = seconds(document(lines: 1_600))
        let ratio = large / max(small, .leastNonzeroMagnitude)
        #expect(ratio < 3.0, "行数 2 倍で所要時間が \(ratio) 倍になった（線形なら約 2.0）")
    }

    @Test("1 万行でも現実的な時間で終わる")
    func largeDocumentFinishesQuickly() {
        // 修正前は 1 万行で 16.3 秒かかっていた。余裕を持って 1.0 秒を上限とする。
        let elapsed = seconds(document(lines: 10_000))
        #expect(elapsed < 1.0, "1 万行の styler に \(elapsed) 秒かかった")
    }

    @Test("セレクションありでも線形")
    func withSelectionStaysLinear() {
        let build = { (n: Int) -> String in self.document(lines: n) }
        let selection = Selection(caret: 100)
        func measure(_ n: Int) -> Double {
            let text = build(n)
            let start = DispatchTime.now().uptimeNanoseconds
            _ = LivePreviewStyler.runs(text: text, selection: selection, focused: true)
            return Double(DispatchTime.now().uptimeNanoseconds - start) / 1_000_000_000
        }
        _ = measure(800)
        let ratio = measure(1_600) / max(measure(800), .leastNonzeroMagnitude)
        #expect(ratio < 3.0, "行数 2 倍で所要時間が \(ratio) 倍になった（線形なら約 2.0）")
    }
}

/// トークナイザが行長に対して線形に留まることの検証。
@Suite("トークナイザが線形時間で走る")
struct MarkdownTokenizerComplexityTests {

    private func seconds(_ text: String) -> Double {
        let start = DispatchTime.now().uptimeNanoseconds
        _ = MarkdownTokenizer.tokenize(text)
        return Double(DispatchTime.now().uptimeNanoseconds - start) / 1_000_000_000
    }

    @Test("閉じない [ が多い長い行でも二次にならない")
    func unclosedBracketsStayLinear() {
        _ = seconds(String(repeating: "[", count: 4_000))   // 暖機
        let small = seconds(String(repeating: "[", count: 4_000))
        let large = seconds(String(repeating: "[", count: 8_000))
        let ratio = large / max(small, .leastNonzeroMagnitude)
        #expect(ratio < 3.0, "行長 2 倍で所要時間が \(ratio) 倍になった（線形なら約 2.0）")
    }

    @Test("閉じない [ が大量にあっても現実的な時間で終わる")
    func unclosedBracketsFinishQuickly() {
        // 修正前は 8,000 個で 0.372 秒かかっていた。
        let elapsed = seconds(String(repeating: "[", count: 8_000))
        #expect(elapsed < 0.1, "8,000 個の閉じない [ に \(elapsed) 秒かかった")
    }

    @Test("リンクは従来どおり認識される")
    func linksStillTokenized() {
        let kinds = MarkdownTokenizer.tokenize("see [docs](https://e.com) here").map(\.kind)
        #expect(kinds.contains(.linkText))
        #expect(kinds.contains(.linkURL))
    }
}
