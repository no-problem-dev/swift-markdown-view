import Testing
import SwiftMarkdownEditorCore
@testable import SwiftMarkdownEditorRules

/// リストマーカーの解析。
///
/// `ListContinuationRule` の挙動はすべてここの解析結果に従うため、
/// ルール経由の統合テストだけだと「どのマーカーを認識できていないか」が見えない。
@Suite("ListPrefix の解析")
struct ListPrefixTests {

    // MARK: 箇条書き

    @Test("箇条書きマーカーを認識する", arguments: ["-", "*", "+"])
    func parsesBulletMarkers(marker: String) {
        let prefix = ListPrefix.parse("\(marker) item")
        guard case .bullet(let char)? = prefix?.kind else {
            Issue.record("箇条書きとして解析されなかった: \(marker)")
            return
        }
        #expect(String(char) == marker)
        #expect(prefix?.contentStart == 2)
    }

    @Test("マーカーの後ろに空白が無ければリストではない")
    func requiresSpaceAfterBullet() {
        #expect(ListPrefix.parse("-item") == nil)
        #expect(ListPrefix.parse("-") == nil)
    }

    // MARK: 番号付き

    @Test("番号付きマーカーを認識する", arguments: [".", ")"])
    func parsesOrderedMarkers(delimiter: String) {
        let prefix = ListPrefix.parse("3\(delimiter) item")
        guard case .ordered(let number, let char)? = prefix?.kind else {
            Issue.record("番号付きとして解析されなかった: \(delimiter)")
            return
        }
        #expect(number == 3)
        #expect(String(char) == delimiter)
    }

    @Test("複数桁の番号を解析する")
    func parsesMultiDigitNumbers() {
        guard case .ordered(let number, _)? = ListPrefix.parse("117. item")?.kind else {
            Issue.record("番号付きとして解析されなかった")
            return
        }
        #expect(number == 117)
    }

    @Test("区切り文字の後ろに空白が無ければリストではない")
    func requiresSpaceAfterOrderedDelimiter() {
        #expect(ListPrefix.parse("1.item") == nil)
        #expect(ListPrefix.parse("1") == nil)
    }

    // MARK: インデント

    @Test("インデントを保持する")
    func preservesIndentation() {
        let prefix = ListPrefix.parse("    - nested")
        #expect(prefix?.indentation == "    ")
        #expect(prefix?.contentStart == 6)
    }

    @Test("タブのインデントも保持する")
    func preservesTabIndentation() {
        #expect(ListPrefix.parse("\t- nested")?.indentation == "\t")
    }

    // MARK: チェックボックス

    @Test("チェックボックスを認識する", arguments: ["[ ]", "[x]", "[X]"])
    func parsesCheckboxes(box: String) {
        let prefix = ListPrefix.parse("- \(box) task")
        #expect(prefix?.hasCheckbox == true)
        #expect(prefix?.contentStart == 6)
    }

    @Test("チェックボックスでない角括弧は無視する")
    func rejectsNonCheckboxBrackets() {
        #expect(ListPrefix.parse("- [ab] link")?.hasCheckbox == false)
    }

    // MARK: リストでない行

    @Test("リストでない行は nil", arguments: ["", "plain text", "# heading", "> quote", "  "])
    func rejectsNonListLines(line: String) {
        #expect(ListPrefix.parse(line) == nil)
    }

    // MARK: 次のマーカー生成

    @Test("箇条書きは同じマーカーを引き継ぐ")
    func nextMarkerKeepsBullet() {
        #expect(ListPrefix.parse("* item")?.nextMarker() == "* ")
    }

    @Test("番号付きは番号を 1 つ進める")
    func nextMarkerIncrementsNumber() {
        #expect(ListPrefix.parse("7. item")?.nextMarker() == "8. ")
    }

    @Test("番号付きの区切り文字を引き継ぐ")
    func nextMarkerKeepsDelimiter() {
        #expect(ListPrefix.parse("2) item")?.nextMarker() == "3) ")
    }

    @Test("チェック済みでも次は未チェックになる")
    func nextMarkerResetsCheckbox() {
        #expect(ListPrefix.parse("- [x] done")?.nextMarker() == "- [ ] ")
    }

    @Test("インデントを引き継ぐ")
    func nextMarkerKeepsIndentation() {
        #expect(ListPrefix.parse("    - nested")?.nextMarker() == "    - ")
    }
}
