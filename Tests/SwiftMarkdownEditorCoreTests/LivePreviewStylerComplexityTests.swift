import Foundation
import Testing
@testable import SwiftMarkdownEditorCore

/// 計算量の退行を検出するための共通計測。
///
/// 時間の絶対値ではなく**入力を 4 倍にしたときの伸び**で判定する。線形なら約 4 倍、
/// 二次なら約 16 倍になるので、閾値 8 で十分な余裕を持って区別できる
/// （2 倍比較だと線形 2.0 / 二次 4.0 で間隔が狭く、負荷変動で誤検出する）。
///
/// 各計測は複数回試行して**最小値**を採る。マイクロベンチマークで外乱を除く定石。
enum ComplexityProbe {

    static func bestSeconds(trials: Int = 5, _ body: () -> Void) -> Double {
        var best = Double.greatestFiniteMagnitude
        for _ in 0..<trials {
            let start = DispatchTime.now().uptimeNanoseconds
            body()
            let elapsed = Double(DispatchTime.now().uptimeNanoseconds - start) / 1_000_000_000
            best = Swift.min(best, elapsed)
        }
        return best
    }

    /// 入力を 4 倍にしたときの所要時間の伸び。
    static func growthOver4x(base: Int, _ run: @escaping (Int) -> Void) -> Double {
        _ = bestSeconds(trials: 2) { run(base) }   // 暖機
        let small = bestSeconds { run(base) }
        let large = bestSeconds { run(base * 4) }
        return large / Swift.max(small, .leastNonzeroMagnitude)
    }

    /// 線形とみなす上限。線形 ≒ 4.0 / 二次 ≒ 16.0。
    static let linearCeiling = 8.0
}

/// ライブプレビューのスタイル計算が文書長に対して線形に留まることの検証。
///
/// この経路は打鍵ごと・カーソル移動ごとに `@MainActor` 上で走る。二次に膨らむと
/// UI がそのまま固まるため、性能ではなく機能の欠陥として現れる。
@Suite("ライブプレビューが線形時間で走る")
struct LivePreviewStylerComplexityTests {

    private static func document(lines: Int) -> String {
        String(repeating: "some **bold** and *it* text here\n", count: lines)
    }

    @Test("行数を 4 倍にしても所要時間は線形の範囲に留まる")
    func stylerStaysLinear() {
        let ratio = ComplexityProbe.growthOver4x(base: 500) { n in
            _ = LivePreviewStyler.runs(text: Self.document(lines: n), selection: nil, focused: false)
        }
        #expect(ratio < ComplexityProbe.linearCeiling, "行数 4 倍で \(ratio) 倍になった（線形なら約 4.0）")
    }

    @Test("セレクションありでも線形")
    func withSelectionStaysLinear() {
        let selection = Selection(caret: 100)
        let ratio = ComplexityProbe.growthOver4x(base: 500) { n in
            _ = LivePreviewStyler.runs(text: Self.document(lines: n), selection: selection, focused: true)
        }
        #expect(ratio < ComplexityProbe.linearCeiling, "行数 4 倍で \(ratio) 倍になった（線形なら約 4.0）")
    }

    @Test("1 万行でも現実的な時間で終わる")
    func largeDocumentFinishesQuickly() {
        // 修正前は 1 万行で 16.3 秒かかっていた。余裕を持って 2.0 秒を上限とする。
        let text = Self.document(lines: 10_000)
        let elapsed = ComplexityProbe.bestSeconds(trials: 3) {
            _ = LivePreviewStyler.runs(text: text, selection: nil, focused: false)
        }
        #expect(elapsed < 2.0, "1 万行の styler に \(elapsed) 秒かかった")
    }
}

/// トークナイザが行長に対して線形に留まることの検証。
@Suite("トークナイザが線形時間で走る")
struct MarkdownTokenizerComplexityTests {

    @Test("閉じない [ が多い長い行でも線形の範囲に留まる")
    func unclosedBracketsStayLinear() {
        let ratio = ComplexityProbe.growthOver4x(base: 2_000) { n in
            _ = MarkdownTokenizer.tokenize(String(repeating: "[", count: n))
        }
        #expect(ratio < ComplexityProbe.linearCeiling, "行長 4 倍で \(ratio) 倍になった（線形なら約 4.0）")
    }

    @Test("閉じない [ が大量にあっても現実的な時間で終わる")
    func unclosedBracketsFinishQuickly() {
        // 修正前は 8,000 個で 0.372 秒かかっていた。
        let text = String(repeating: "[", count: 8_000)
        let elapsed = ComplexityProbe.bestSeconds { _ = MarkdownTokenizer.tokenize(text) }
        #expect(elapsed < 0.1, "8,000 個の閉じない [ に \(elapsed) 秒かかった")
    }

    @Test("リンクは従来どおり認識される")
    func linksStillTokenized() {
        let kinds = MarkdownTokenizer.tokenize("see [docs](https://e.com) here").map(\.kind)
        #expect(kinds.contains(.linkText))
        #expect(kinds.contains(.linkURL))
    }
}
