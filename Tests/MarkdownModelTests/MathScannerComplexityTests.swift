import Foundation
import Testing
@testable import MarkdownModel

/// 数式スキャナの走査量が入力長に対して線形に留まることの検証。
///
/// 閉じデリミターが見つからないときに走査結果を捨てて再走査すると、`\(` の連続で
/// 二次関数的に膨らむ。`MarkdownContent(parsing:)` は SwiftUI の body 評価から同期で
/// 呼ばれるため、外部由来の Markdown（LLM 出力・ユーザー投稿）で UI が固まる。
///
/// 時間の絶対値ではなく**入力を 4 倍にしたときの伸び**で判定する。線形なら約 4 倍、
/// 二次なら約 16 倍になるので、閾値 8 で余裕を持って区別できる。各計測は複数回試行して
/// 最小値を採り、外乱を除く。
@Suite("数式スキャナが線形時間で走査する")
struct MathScannerComplexityTests {

    private static func bestSeconds(trials: Int = 5, _ body: () -> Void) -> Double {
        var best = Double.greatestFiniteMagnitude
        for _ in 0..<trials {
            let start = DispatchTime.now().uptimeNanoseconds
            body()
            best = Swift.min(best, Double(DispatchTime.now().uptimeNanoseconds - start) / 1_000_000_000)
        }
        return best
    }

    private static func growthOver4x(base: Int, _ build: @escaping (Int) -> String) -> Double {
        _ = bestSeconds(trials: 2) { _ = MarkdownContent(parsing: build(base)) }   // 暖機
        let small = bestSeconds { _ = MarkdownContent(parsing: build(base)) }
        let large = bestSeconds { _ = MarkdownContent(parsing: build(base * 4)) }
        return large / Swift.max(small, .leastNonzeroMagnitude)
    }

    /// 線形とみなす上限。線形 ≒ 4.0 / 二次 ≒ 16.0。
    private static let linearCeiling = 8.0

    @Test("未閉じの \\( が連続しても二次にならない")
    func unclosedInlineMathOpenersStayLinear() {
        let ratio = Self.growthOver4x(base: 2_000) { String(repeating: #"\("#, count: $0) }
        #expect(ratio < Self.linearCeiling, "入力 4 倍で \(ratio) 倍になった（線形なら約 4.0）")
    }

    @Test("未閉じの \\[ が連続しても二次にならない")
    func unclosedDisplayMathOpenersStayLinear() {
        let ratio = Self.growthOver4x(base: 2_000) { String(repeating: #"\["#, count: $0) }
        #expect(ratio < Self.linearCeiling, "入力 4 倍で \(ratio) 倍になった（線形なら約 4.0）")
    }

    @Test("未閉じの \\( が大量にあっても現実的な時間で終わる")
    func unclosedInlineMathOpenersFinishQuickly() {
        // 修正前は 8,000 個で 1.84 秒かかっていた。余裕を持って 0.5 秒を上限とする。
        let source = String(repeating: #"\("#, count: 8_000)
        let elapsed = Self.bestSeconds(trials: 3) { _ = MarkdownContent(parsing: source) }
        #expect(elapsed < 0.5, "8,000 個の未閉じ \\( に \(elapsed) 秒かかった")
    }

    @Test("閉じた数式は従来どおり線形")
    func closedMathStaysLinear() {
        let ratio = Self.growthOver4x(base: 1_000) { String(repeating: "a$$b\n", count: $0) }
        #expect(ratio < Self.linearCeiling, "入力 4 倍で \(ratio) 倍になった（線形なら約 4.0）")
    }
}
