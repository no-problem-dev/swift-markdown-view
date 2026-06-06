import Testing
@testable import SwiftMarkdownView

/// Tests for math detection in Markdown parsing.
///
/// Math regions are extracted before swift-markdown parsing (a `\(...\)`
/// delimiter cannot survive Markdown escape processing) and restored into
/// `.math` / `.inlineMath` AST nodes afterwards.
struct MathParsingTests {

    // MARK: - Display Math Blocks

    @Test("Standalone double-dollar math parses as a math block")
    func standaloneDoubleDollar() {
        let content = MarkdownContent(parsing: "$$E = mc^2$$")

        #expect(content.blocks == [.math("E = mc^2")])
    }

    @Test("Bracket display math parses as a math block")
    func bracketDisplay() {
        let content = MarkdownContent(parsing: #"\[x^2 + y^2 = z^2\]"#)

        #expect(content.blocks == [.math("x^2 + y^2 = z^2")])
    }

    @Test("Multiline display math between paragraphs")
    func multilineDisplayBetweenParagraphs() {
        let content = MarkdownContent(parsing: """
        The quadratic formula is:

        $$
        x = \\frac{-b \\pm \\sqrt{b^2 - 4ac}}{2a}
        $$

        where the discriminant matters.
        """)

        #expect(content.blocks.count == 3)
        #expect(content.blocks[1] == .math(#"x = \frac{-b \pm \sqrt{b^2 - 4ac}}{2a}"#))

        guard case .paragraph = content.blocks[0], case .paragraph = content.blocks[2] else {
            Issue.record("Expected paragraphs around the math block")
            return
        }
    }

    @Test("Display math in the middle of a paragraph becomes its own block")
    func displayMidParagraph() {
        let content = MarkdownContent(parsing: "Einstein said $$E = mc^2$$ in 1905.")

        #expect(content.blocks.count == 3)
        #expect(content.blocks[1] == .math("E = mc^2"))
    }

    @Test("math fenced code block parses as a math block")
    func mathFence() {
        let content = MarkdownContent(parsing: """
        ```math
        \\sum_{i=1}^{n} i
        ```
        """)

        #expect(content.blocks == [.math(#"\sum_{i=1}^{n} i"#)])
    }

    // MARK: - Inline Math

    @Test("Single-dollar math parses as inline math within a paragraph")
    func singleDollarInline() {
        let content = MarkdownContent(parsing: "The value $x = 5$ is constant.")

        #expect(content.blocks == [.paragraph([
            .text("The value "),
            .inlineMath("x = 5"),
            .text(" is constant.")
        ])])
    }

    @Test("Parenthesis math parses as inline math")
    func parenthesisInline() {
        let content = MarkdownContent(parsing: #"where \(a \neq 0\) holds"#)

        #expect(content.blocks == [.paragraph([
            .text("where "),
            .inlineMath(#"a \neq 0"#),
            .text(" holds")
        ])])
    }

    @Test("Inline math inside emphasis is preserved")
    func inlineMathInsideEmphasis() {
        let content = MarkdownContent(parsing: "see *the value $x$ here*")

        #expect(content.blocks == [.paragraph([
            .text("see "),
            .emphasis([
                .text("the value "),
                .inlineMath("x"),
                .text(" here")
            ])
        ])])
    }

    @Test("Multiple inline math in one paragraph")
    func multipleInline() {
        let content = MarkdownContent(parsing: "$a$ and $b$")

        #expect(content.blocks == [.paragraph([
            .inlineMath("a"),
            .text(" and "),
            .inlineMath("b")
        ])])
    }

    @Test("Inline math subscripts are not eaten by emphasis parsing")
    func subscriptsSurviveEmphasis() {
        let content = MarkdownContent(parsing: "compare $a_b$ and $c_d$ values")

        #expect(content.blocks == [.paragraph([
            .text("compare "),
            .inlineMath("a_b"),
            .text(" and "),
            .inlineMath("c_d"),
            .text(" values")
        ])])
    }

    // MARK: - Non-Math (False-Positive Guards)

    @Test("Currency amounts stay plain text")
    func currency() {
        let content = MarkdownContent(parsing: "It costs $5 and $10 in total.")

        #expect(content.blocks == [.paragraph([
            .text("It costs $5 and $10 in total.")
        ])])
    }

    @Test("Dollars inside inline code stay code")
    func dollarInCodeSpan() {
        let content = MarkdownContent(parsing: "Use `$HOME$` here.")

        #expect(content.blocks == [.paragraph([
            .text("Use "),
            .code("$HOME$"),
            .text(" here.")
        ])])
    }

    @Test("Dollars inside fenced code blocks stay code")
    func dollarInFence() {
        let content = MarkdownContent(parsing: """
        ```swift
        let price = "$5$"
        ```
        """)

        #expect(content.blocks == [.codeBlock(language: "swift", code: "let price = \"$5$\"\n")])
    }

    @Test("Escaped dollars stay literal text")
    func escapedDollars() {
        let content = MarkdownContent(parsing: #"Price is \$5 and \$10."#)

        #expect(content.blocks == [.paragraph([
            .text("Price is $5 and $10.")
        ])])
    }

    // MARK: - Document Integration

    @Test("LLM-style mixed document")
    func llmMixedDocument() {
        let content = MarkdownContent(parsing: """
        ## Quadratic Formula

        For $ax^2 + bx + c = 0$ the solution is:

        $$x = \\frac{-b \\pm \\sqrt{b^2 - 4ac}}{2a}$$

        - cost: $5
        - condition: \\(a \\neq 0\\)
        """)

        guard content.blocks.count == 4 else {
            Issue.record("Expected 4 blocks, got \(content.blocks.count): \(content.blocks)")
            return
        }

        guard case .heading(let level, _) = content.blocks[0] else {
            Issue.record("Expected heading")
            return
        }
        #expect(level == 2)

        #expect(content.blocks[1] == .paragraph([
            .text("For "),
            .inlineMath("ax^2 + bx + c = 0"),
            .text(" the solution is:")
        ]))

        #expect(content.blocks[2] == .math(#"x = \frac{-b \pm \sqrt{b^2 - 4ac}}{2a}"#))

        guard case .unorderedList(let items) = content.blocks[3] else {
            Issue.record("Expected list")
            return
        }
        #expect(items.count == 2)
        #expect(items[0].blocks == [.paragraph([.text("cost: $5")])])
        #expect(items[1].blocks == [.paragraph([
            .text("condition: "),
            .inlineMath(#"a \neq 0"#)
        ])])
    }
}
