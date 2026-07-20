import Foundation

/// ある範囲への単一スタイル貢献。貢献は *加算的* で、
/// TextKit 層がベース属性にマージする（例：`italic` 済み範囲に `bold` を適用すると bold-italic になる）。
/// `conceal` 範囲はコンテンツ範囲と重複しないため衝突は起きない。
public struct StyleRun: Equatable, Sendable {
    public enum Trait: Equatable, Sendable {
        case bold
        case italic
        case monospace
        case strikethrough
        /// ATX 見出しのコンテンツ — レベル（1–6）に応じて大きく太字でレンダリングされる。
        case heading(level: Int)
        /// テキストを保持したまま範囲を視覚的に非表示にする（マーカー用）。
        case conceal
    }

    public var range: TextSpan
    public var trait: Trait

    public init(range: TextSpan, trait: Trait) {
        self.range = range
        self.trait = trait
    }
}

/// ライブプレビューのスタイルを計算する。コンテンツにスタイルを適用し、デリミタマーカーを非表示にする。
/// ただしセレクションが触れる行ではマーカーを表示する
/// （Obsidian/Typora の「カーソル行はソースを表示」ルール。CodeMirror 6 および swift-markdown-engine で確認済み）。
///
/// 純粋で UI に依存しない。セマンティックな ``StyleRun`` を返し、
/// TextKit 層が `conceal` をクリアカラー＋極小フォント＋負カーニングで実装し、
/// 各トレイトをフォントのシンボリックトレイトにマッピングする。
public enum LivePreviewStyler {

    /// - Parameters:
    ///   - text: ドキュメントのソーステキスト。
    ///   - selection: 現在のセレクション。編集中でない場合は `nil`。
    ///   - focused: エディタがフォーカスされているかどうか。`false` のとき全て非表示になる（読み取り専用のレンダリング状態）。
    public static func runs(text: String, selection: Selection?, focused: Bool) -> [StyleRun] {
        // 行境界は一度だけ求める。スパンごとに全文を走査すると文書長に対して二次になり、
        // 打鍵とカーソル移動のたびに走るためエディタが実用にならない。
        let lines = LineIndex(text)
        let activeLine = (focused ? selection : nil).map { activeLineSpan(lines: lines, selection: $0) }

        var runs: [StyleRun] = []

        // ブロック構造はトークナイザだけが知っている（フェンスの開閉を状態として追う）。
        // インラインスパンの解析器は行単位でブロック文脈を持たないため、フェンスの範囲を
        // ここで渡して除外する。渡さないと ```` ```let a = **b** ``` ```` の `**` が
        // conceal されて、ユーザーのソースコードから記号が消えて表示される。
        let tokens = MarkdownTokenizer.tokenize(text)
        appendHeadingRuns(lines: lines, tokens: tokens, activeLine: activeLine, into: &runs)

        let verbatim = MarkdownTokenizer.fencedCodeRanges(tokens)
        for span in InlineSpanParser.parse(text) {
            guard !isInsideVerbatim(span.fullRange, verbatim) else { continue }

            // Content styling is always applied (revealed lines keep bold etc.).
            if let trait = contentTrait(for: span.kind), span.contentRange.length > 0 {
                runs.append(StyleRun(range: span.contentRange, trait: trait))
            }

            // Markers are concealed unless this span's line is active.
            let revealed = activeLine.map { $0.overlaps(lines.lineRange(containing: span.fullRange.lowerBound)) } ?? false
            if !revealed {
                for marker in span.markerRanges {
                    runs.append(StyleRun(range: marker, trait: .conceal))
                }
            }
        }
        return runs
    }

    // MARK: - Verbatim (fenced code) regions

    /// 昇順・非重複の範囲列に対する二分探索。スパンごとに線形探索すると文書長に対して
    /// 二次になるため、探索側で潰しておく。
    private static func isInsideVerbatim(_ span: TextSpan, _ ranges: [TextSpan]) -> Bool {
        var low = 0
        var high = ranges.count - 1
        while low <= high {
            let mid = (low + high) / 2
            let range = ranges[mid]
            if span.lowerBound >= range.upperBound {
                low = mid + 1
            } else if span.upperBound <= range.lowerBound {
                high = mid - 1
            } else {
                return true
            }
        }
        return false
    }

    // MARK: - Block headings

    /// 各 ATX 見出しのコンテンツに `.heading(level)` ランを出力し、`#…` マーカー（および直後のスペース）を非表示にする。
    /// ただし見出しの行がアクティブな場合はマーカーを表示する（インラインスパンのマーカー表示ルールと一致）。
    private static func appendHeadingRuns(
        lines: LineIndex,
        tokens: [MarkdownToken],
        activeLine: TextSpan?,
        into runs: inout [StyleRun]
    ) {
        var i = 0
        while i < tokens.count {
            guard tokens[i].kind == .headingMarker else { i += 1; continue }
            let marker = tokens[i].range
            let level = max(1, min(6, marker.length))
            var concealUpper = marker.upperBound

            // Pair with the following `.heading` content token when present.
            if i + 1 < tokens.count, tokens[i + 1].kind == .heading {
                let content = tokens[i + 1].range
                runs.append(StyleRun(range: content, trait: .heading(level: level)))
                concealUpper = content.lowerBound   // conceal the marker + trailing space
                i += 1
            }

            let line = lines.lineRange(containing: marker.lowerBound)
            let revealed = activeLine.map { $0.overlaps(line) } ?? false
            if !revealed, concealUpper > marker.lowerBound {
                runs.append(StyleRun(
                    range: TextSpan(lowerBound: marker.lowerBound, upperBound: concealUpper),
                    trait: .conceal
                ))
            }
            i += 1
        }
    }

    // MARK: - Helpers

    private static func contentTrait(for kind: InlineSpan.Kind) -> StyleRun.Trait? {
        switch kind {
        case .strong: return .bold
        case .emphasis: return .italic
        case .strikethrough: return .strikethrough
        case .code: return .monospace
        }
    }

    /// セレクションが触れる行の合計範囲（anchor 行から head 行まで）。
    private static func activeLineSpan(lines: LineIndex, selection: Selection) -> TextSpan {
        let lower = lines.lineRange(containing: selection.range.lowerBound).lowerBound
        let upper = lines.lineRange(containing: selection.range.upperBound).upperBound
        return TextSpan(lowerBound: lower, upperBound: upper)
    }
}
