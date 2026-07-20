import Testing
import SwiftMarkdownEditorCore
@testable import SwiftMarkdownEditorRules

/// 各ルール単体の挙動。
///
/// 既存の `InputRuleTests` は `InputRuleProcessor.standard` 経由の統合テストで、
/// 平坦なリストしか通していない。ここでは各ルールを直接呼び、
/// 「発火しない条件」も含めて固める（誤発火は誤動作より気づきにくい）。
@Suite("入力ルール単体")
struct IndividualRuleTests {

    private func state(_ text: String) -> EditorState {
        EditorState(text: text)
    }

    // MARK: - ListContinuationRule

    private let list = ListContinuationRule()

    private func pressEnter(_ text: String, at caret: Int) -> (text: String, caret: Int)? {
        guard let t = list.transform(
            state: state(text),
            inserting: "\n",
            replacing: TextSpan(caret: caret)
        ) else { return nil }
        return (t.change.apply(to: text), t.selection.head)
    }

    @Test("入れ子のリストでインデントを引き継ぐ")
    func continuesNestedList() {
        let source = "- top\n    - nested"
        let result = pressEnter(source, at: source.utf16Length)
        #expect(result?.text == "- top\n    - nested\n    - ")
    }

    @Test("入れ子のチェックボックスも引き継ぐ")
    func continuesNestedCheckbox() {
        let source = "  - [x] done"
        let result = pressEnter(source, at: source.utf16Length)
        #expect(result?.text == "  - [x] done\n  - [ ] ")
    }

    @Test("番号付きリストは番号が進む")
    func incrementsOrderedList() {
        let source = "9. nine"
        #expect(pressEnter(source, at: source.utf16Length)?.text == "9. nine\n10. ")
    }

    @Test("空のアイテムでリストを抜ける")
    func exitsListOnEmptyItem() {
        let source = "- item\n- "
        let result = pressEnter(source, at: source.utf16Length)
        #expect(result?.text == "- item\n")
    }

    @Test("空の入れ子アイテムもマーカーごと消える")
    func exitsNestedListOnEmptyItem() {
        let source = "- top\n    - "
        #expect(pressEnter(source, at: source.utf16Length)?.text == "- top\n")
    }

    @Test("改行以外では発火しない")
    func doesNotFireOnNonNewline() {
        #expect(list.transform(state: state("- item"), inserting: "a", replacing: TextSpan(caret: 6)) == nil)
    }

    @Test("選択範囲があるときは発火しない")
    func doesNotFireOnSelection() {
        let range = TextSpan(lowerBound: 2, upperBound: 6)
        #expect(list.transform(state: state("- item"), inserting: "\n", replacing: range) == nil)
    }

    @Test("リストでない行では発火しない")
    func doesNotFireOnPlainLine() {
        #expect(pressEnter("plain text", at: 10) == nil)
    }

    @Test("リスト編集は undo をまとめない")
    func listEditIsItsOwnUndoStep() {
        let source = "- item"
        let transform = list.transform(
            state: state(source),
            inserting: "\n",
            replacing: TextSpan(caret: source.utf16Length)
        )
        #expect(transform?.allowCoalescing == false)
    }

    // MARK: - WrapSelectionRule

    private let wrapRule = WrapSelectionRule()

    private func wrap(_ text: String, _ range: TextSpan, with delimiter: String) -> (text: String, selection: Selection)? {
        guard let t = wrapRule.transform(state: state(text), inserting: delimiter, replacing: range) else {
            return nil
        }
        return (t.change.apply(to: text), t.selection)
    }

    @Test("選択をデリミタで囲む", arguments: ["*", "_", "`"])
    func wrapsSelection(delimiter: String) {
        let result = wrap("hello world", TextSpan(lowerBound: 0, upperBound: 5), with: delimiter)
        #expect(result?.text == "\(delimiter)hello\(delimiter) world")
    }

    @Test("囲んだ後も内側のテキストが選択されたままになる")
    func keepsInnerTextSelected() {
        let result = wrap("hello world", TextSpan(lowerBound: 0, upperBound: 5), with: "*")
        // "*hello*" の内側 "hello" は 1..6。
        #expect(result?.selection.anchor == 1)
        #expect(result?.selection.head == 6)
    }

    @Test("選択が空なら発火しない")
    func doesNotFireOnEmptySelection() {
        #expect(wrapRule.transform(state: state("hello"), inserting: "*", replacing: TextSpan(caret: 2)) == nil)
    }

    @Test("デリミタ以外の文字では発火しない")
    func doesNotFireOnNonDelimiter() {
        let range = TextSpan(lowerBound: 0, upperBound: 5)
        #expect(wrapRule.transform(state: state("hello"), inserting: "a", replacing: range) == nil)
    }

    @Test("デリミタ集合を差し替えられる")
    func honorsCustomDelimiters() {
        let rule = WrapSelectionRule(delimiters: ["~"])
        let range = TextSpan(lowerBound: 0, upperBound: 5)

        #expect(rule.transform(state: state("hello"), inserting: "~", replacing: range) != nil)
        // 既定に含まれる * でも、差し替えた集合に無ければ発火しない。
        #expect(rule.transform(state: state("hello"), inserting: "*", replacing: range) == nil)
    }

    @Test("複数行の選択も囲める")
    func wrapsMultilineSelection() {
        let source = "one\ntwo"
        let result = wrap(source, TextSpan(lowerBound: 0, upperBound: source.utf16Length), with: "`")
        #expect(result?.text == "`one\ntwo`")
    }

    // MARK: - InputRuleProcessor

    @Test("先にマッチしたルールが採用される")
    func firstMatchingRuleWins() {
        let processor = InputRuleProcessor(rules: [
            WrapSelectionRule(delimiters: ["*"]),
            WrapSelectionRule(delimiters: ["*"])
        ])
        let range = TextSpan(lowerBound: 0, upperBound: 5)
        let result = processor.transform(state: state("hello"), inserting: "*", replacing: range)
        // 二重に囲まれていないこと（1 つ目で止まる）。
        #expect(result?.change.replacement == "*hello*")
    }

    @Test("どのルールもマッチしなければ nil")
    func returnsNilWhenNoRuleMatches() {
        let processor = InputRuleProcessor(rules: [])
        #expect(processor.transform(state: state("x"), inserting: "\n", replacing: TextSpan(caret: 1)) == nil)
    }

    @Test("標準セットはリスト継続とラッピングを含む")
    func standardSetHandlesBothRules() {
        let processor = InputRuleProcessor.standard
        let listResult = processor.transform(
            state: state("- item"),
            inserting: "\n",
            replacing: TextSpan(caret: 6)
        )
        let wrapResult = processor.transform(
            state: state("hello"),
            inserting: "*",
            replacing: TextSpan(lowerBound: 0, upperBound: 5)
        )
        #expect(listResult != nil)
        #expect(wrapResult != nil)
    }
}

/// リスト継続ルールがブロック文脈とキャレット位置を尊重することの検証。
@Suite("リスト継続ルールの文脈判定")
struct ListContinuationContextTests {

    private func apply(_ text: String, caret: Int) -> String? {
        let state = EditorState(text: text, selection: Selection(caret: caret))
        let rule = ListContinuationRule()
        guard let transform = rule.transform(
            state: state,
            inserting: "\n",
            replacing: TextSpan(lowerBound: caret, upperBound: caret)
        ) else { return nil }
        return transform.change.apply(to: text)
    }

    @Test("行頭で Enter を押してもマーカーが二重にならない")
    func caretBeforeMarkerDoesNotDuplicate() {
        // ルールは発火せず、通常の改行に委ねる（"\n- - abc" になっていた）。
        #expect(apply("- abc", caret: 0) == nil)
    }

    @Test("マーカーの途中で Enter を押しても発火しない")
    func caretInsideMarkerDoesNotFire() {
        #expect(apply("- abc", caret: 1) == nil)
    }

    @Test("内容の直前で Enter を押すと項目が分かれる")
    func caretAtContentStartSplitsItem() {
        #expect(apply("- abc", caret: 2) == "- \n- abc")
    }

    @Test("行末の Enter は従来どおり継続する")
    func caretAtEndContinues() {
        #expect(apply("- abc", caret: 5) == "- abc\n- ")
    }

    @Test("フェンスコードの中では発火しない")
    func insideFencedCodeDoesNotFire() {
        // "```\n- item\n```" のキャレット 10（"- item" の行末）
        #expect(apply("```\n- item\n```", caret: 10) == nil)
    }

    @Test("フェンスコードの外では従来どおり発火する")
    func outsideFencedCodeStillFires() {
        let text = "```\ncode\n```\n\n- item"
        #expect(apply(text, caret: text.utf16Length) == text + "\n- ")
    }
}
