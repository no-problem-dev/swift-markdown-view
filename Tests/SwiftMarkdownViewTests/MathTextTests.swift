import Testing
@testable import SwiftMarkdownView

/// Tests for the segmentation behind ``MathText``.
///
/// MathText splits single-line text (headings, labels) into text and math
/// parts via MathScanner — the cases here mirror LLM output observed in
/// A2UI data models, where even scalar answers arrive as `$$-6$$`.
struct MathTextTests {

    @Test("Scalar display math is a single math part")
    func scalarDisplayMath() {
        #expect(MathScanner.parts(in: "$$-6$$") == [.math(latex: "-6", isDisplay: true)])
    }

    @Test("Heading text with trailing inline math")
    func headingWithInlineMath() {
        #expect(MathScanner.parts(in: "答え: $x = 3$") == [
            .text("答え: "),
            .math(latex: "x = 3", isDisplay: false),
        ])
    }

    @Test("Currency does not become math", arguments: [
        "costs $5 and $10 total",
        "$ 100 の予算",
    ])
    func currencyStaysText(source: String) {
        #expect(MathScanner.parts(in: source) == [.text(source)])
    }

    @Test("Backslash-paren inline math in label text")
    func backslashParen() {
        #expect(MathScanner.parts(in: #"条件: \(a \neq 0\)"#) == [
            .text("条件: "),
            .math(latex: #"a \neq 0"#, isDisplay: false),
        ])
    }
}
