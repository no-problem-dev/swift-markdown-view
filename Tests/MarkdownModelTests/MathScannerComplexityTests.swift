import Foundation
import Testing
@testable import MarkdownModel

/// 数式スキャナの走査量が入力長に対して線形に留まることの検証。
///
/// 閉じデリミターが見つからないときに走査結果を捨てて再走査すると、`\(` の連続で
/// 二次関数的に膨らむ。`MarkdownContent(parsing:)` は SwiftUI の body 評価から同期で
/// 呼ばれるため、外部由来の Markdown（LLM 出力・ユーザー投稿）で UI が固まる。
///
/// 時間ではなく**倍率**で判定する。線形なら入力 2 倍で時間も約 2 倍、二次なら約 4 倍。
/// マシン性能に依存しないので CI でも安定する。
@Suite("数式スキャナが線形時間で走査する")
struct MathScannerComplexityTests {

    private func seconds(parsing source: String) -> Double {
        let start = DispatchTime.now().uptimeNanoseconds
        _ = MarkdownContent(parsing: source)
        return Double(DispatchTime.now().uptimeNanoseconds - start) / 1_000_000_000
    }

    /// 入力を 2 倍にしたときの所要時間の伸び。線形 ≒ 2.0、二次 ≒ 4.0。
    private func growthRatio(_ build: (Int) -> String, base: Int) -> Double {
        // 1 回目は暖機に使い、計測には含めない。
        _ = seconds(parsing: build(base))
        let small = seconds(parsing: build(base))
        let large = seconds(parsing: build(base * 2))
        guard small > 0 else { return 1 }
        return large / small
    }

    @Test("未閉じの \\( が連続しても二次にならない")
    func unclosedInlineMathOpenersStayLinear() {
        let ratio = growthRatio({ String(repeating: #"\("#, count: $0) }, base: 4_000)
        // 二次なら約 4.0。3.0 を超えたら退行とみなす。
        #expect(ratio < 3.0, "入力 2 倍で所要時間が \(ratio) 倍になった（線形なら約 2.0）")
    }

    @Test("未閉じの \\[ が連続しても二次にならない")
    func unclosedDisplayMathOpenersStayLinear() {
        let ratio = growthRatio({ String(repeating: #"\["#, count: $0) }, base: 4_000)
        #expect(ratio < 3.0, "入力 2 倍で所要時間が \(ratio) 倍になった（線形なら約 2.0）")
    }

    @Test("未閉じの \\( が大量にあっても現実的な時間で終わる")
    func unclosedInlineMathOpenersFinishQuickly() {
        // 修正前は 8,000 個で 1.84 秒かかっていた。余裕を持って 0.5 秒を上限とする。
        let elapsed = seconds(parsing: String(repeating: #"\("#, count: 8_000))
        #expect(elapsed < 0.5, "8,000 個の未閉じ \\( に \(elapsed) 秒かかった")
    }

    @Test("閉じた数式は従来どおり線形")
    func closedMathStaysLinear() {
        let ratio = growthRatio({ String(repeating: "a$$b\n", count: $0) }, base: 2_000)
        #expect(ratio < 3.0, "入力 2 倍で所要時間が \(ratio) 倍になった（線形なら約 2.0）")
    }
}
