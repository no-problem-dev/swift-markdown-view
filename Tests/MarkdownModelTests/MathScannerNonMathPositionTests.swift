import Testing
@testable import MarkdownModel

/// 数式スキャナが「ドキュメント構造上は数式になり得ない位置」を壊さないことの検証。
///
/// スキャナは構文木を持たず生ソース上を走るため、リンク宛先や画像ソースの中の `$...$` も
/// 一律に数式として拾う。そこを原文へ書き戻さないと、**表示されているリンクと実際に開く先が
/// 食い違う**。レンダラの正しさとして最も重い破れ方なので、リンク 3 形式と画像を個別に検証する。
@Suite("数式スキャナが非数式位置を壊さない")
struct MathScannerNonMathPositionTests {

    private func inlines(of source: String) -> [MarkdownInline] {
        guard case .paragraph(let inlines)? = MarkdownContent(parsing: source).blocks.first else {
            return []
        }
        return inlines
    }

    // MARK: インラインリンク

    @Test("リンク宛先の $ で URL が書き換わらない")
    func inlineLinkDestinationSurvives() {
        let result = inlines(of: "See [docs](https://e.com/a$b) and [x](https://e.com/c$d).")
        let destinations = result.compactMap { inline -> String? in
            if case .link(let destination, _, _) = inline { return destination }
            return nil
        }
        #expect(destinations == ["https://e.com/a$b", "https://e.com/c$d"])
    }

    @Test("リンクが 2 本とも残る")
    func bothLinksSurvive() {
        let result = inlines(of: "See [docs](https://e.com/a$b) and [x](https://e.com/c$d).")
        let linkCount = result.filter { if case .link = $0 { true } else { false } }.count
        #expect(linkCount == 2)
    }

    @Test("リンクタイトルの $ も原文のまま")
    func linkTitleSurvives() {
        let result = inlines(of: #"[a](https://e.com "cost $5 to $9 total")"#)
        guard case .link(_, let title, _)? = result.first else {
            Issue.record("リンクとしてパースされなかった")
            return
        }
        #expect(title == "cost $5 to $9 total")
    }

    // MARK: autolink

    @Test("autolink の URL が分断されない")
    func autolinkSurvives() {
        let result = inlines(of: "<https://e.com/a$b$c> tail")
        let destinations = result.compactMap { inline -> String? in
            if case .link(let destination, _, _) = inline { return destination }
            return nil
        }
        #expect(destinations == ["https://e.com/a$b$c"])
    }

    // MARK: 参照リンク定義

    @Test("参照リンク定義の URL が分断されない")
    func referenceDefinitionSurvives() {
        let result = inlines(of: "[a]: https://e.com/x$y$z\n\n[a]\n")
        let destinations = result.compactMap { inline -> String? in
            if case .link(let destination, _, _) = inline { return destination }
            return nil
        }
        #expect(destinations == ["https://e.com/x$y$z"])
    }

    // MARK: 画像

    @Test("画像ソースの $ で URL が書き換わらない")
    func imageSourceSurvives() {
        let result = inlines(of: "![alt](https://e.com/i$m$g.png)")
        guard case .image(let source, _, _)? = result.first else {
            Issue.record("画像としてパースされなかった")
            return
        }
        #expect(source == "https://e.com/i$m$g.png")
    }

    // MARK: デリミター種別の保存

    @Test("バックスラッシュ形式のデリミターも原文で復元される")
    func backslashDelimitersRestoreVerbatim() {
        // latex だけを持って書き戻すと `\(x\)` が `$x$` になり URL が別物になる。
        let result = inlines(of: #"[a](https://e.com/p\(x\)q)"#)
        let destinations = result.compactMap { inline -> String? in
            if case .link(let destination, _, _) = inline { return destination }
            return nil
        }
        #expect(destinations == [#"https://e.com/p\(x\)q"#])
    }

    // MARK: 本文側の数式は従来どおり動く

    @Test("本文中の数式は引き続き数式として扱われる")
    func bodyMathStillWorks() {
        let result = inlines(of: "The value $x^2$ matters.")
        let maths = result.compactMap { inline -> String? in
            if case .inlineMath(let latex) = inline { return latex }
            return nil
        }
        #expect(maths == ["x^2"])
    }

    @Test("リンク本文の中の数式は数式のまま")
    func mathInsideLinkContentStillWorks() {
        let result = inlines(of: "[see $x^2$ here](https://e.com/plain)")
        guard case .link(let destination, _, let content)? = result.first else {
            Issue.record("リンクとしてパースされなかった")
            return
        }
        #expect(destination == "https://e.com/plain")
        #expect(content.contains { if case .inlineMath("x^2") = $0 { true } else { false } })
    }
}
