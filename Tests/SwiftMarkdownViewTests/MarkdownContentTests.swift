import Testing
@testable import SwiftMarkdownView

/// Tests for MarkdownContent parsing functionality
struct MarkdownContentTests {

    // MARK: - Plain Text Parsing

    @Test("Plain text parses as single paragraph with text")
    func plainTextParsesAsParagraph() {
        let content = MarkdownContent(parsing: "Hello, World!")

        #expect(content.blocks.count == 1)

        guard case .paragraph(let inlines) = content.blocks.first else {
            Issue.record("Expected paragraph block")
            return
        }

        #expect(inlines.count == 1)

        guard case .text(let text) = inlines.first else {
            Issue.record("Expected text inline")
            return
        }

        #expect(text == "Hello, World!")
    }

    @Test("Empty string parses as empty content")
    func emptyStringParsesAsEmpty() {
        let content = MarkdownContent(parsing: "")

        #expect(content.blocks.isEmpty)
    }

    @Test("Whitespace-only string parses as empty content")
    func whitespaceOnlyParsesAsEmpty() {
        let content = MarkdownContent(parsing: "   \n\t  ")

        #expect(content.blocks.isEmpty)
    }

    // MARK: - Heading Parsing

    @Test("ATX heading level 1 parses correctly")
    func heading1Parses() {
        let content = MarkdownContent(parsing: "# Title")

        #expect(content.blocks.count == 1)

        guard case .heading(let level, let inlines) = content.blocks.first else {
            Issue.record("Expected heading block")
            return
        }

        #expect(level == 1)
        #expect(inlines.count == 1)

        guard case .text(let text) = inlines.first else {
            Issue.record("Expected text inline")
            return
        }

        #expect(text == "Title")
    }

    @Test("ATX headings levels 1-6 parse with correct levels")
    func headingLevelsParse() {
        let sources = [
            "# H1",
            "## H2",
            "### H3",
            "#### H4",
            "##### H5",
            "###### H6"
        ]

        for (index, source) in sources.enumerated() {
            let content = MarkdownContent(parsing: source)
            let expectedLevel = index + 1

            guard case .heading(let level, _) = content.blocks.first else {
                Issue.record("Expected heading block for \(source)")
                continue
            }

            #expect(level == expectedLevel, "Expected level \(expectedLevel) for \(source)")
        }
    }

    // MARK: - Emphasis and Strong Parsing

    @Test("Emphasis (italic) parses correctly")
    func emphasisParses() {
        let content = MarkdownContent(parsing: "This is *italic* text")

        guard case .paragraph(let inlines) = content.blocks.first else {
            Issue.record("Expected paragraph block")
            return
        }

        // Should have: text, emphasis, text
        #expect(inlines.count == 3)

        guard case .emphasis(let emphasisContent) = inlines[1] else {
            Issue.record("Expected emphasis inline")
            return
        }

        guard case .text(let text) = emphasisContent.first else {
            Issue.record("Expected text inside emphasis")
            return
        }

        #expect(text == "italic")
    }

    @Test("Strong (bold) parses correctly")
    func strongParses() {
        let content = MarkdownContent(parsing: "This is **bold** text")

        guard case .paragraph(let inlines) = content.blocks.first else {
            Issue.record("Expected paragraph block")
            return
        }

        #expect(inlines.count == 3)

        guard case .strong(let strongContent) = inlines[1] else {
            Issue.record("Expected strong inline")
            return
        }

        guard case .text(let text) = strongContent.first else {
            Issue.record("Expected text inside strong")
            return
        }

        #expect(text == "bold")
    }

    // MARK: - Code Block Parsing

    @Test("Fenced code block parses correctly")
    func fencedCodeBlockParses() {
        let source = """
        ```swift
        let x = 1
        ```
        """
        let content = MarkdownContent(parsing: source)

        #expect(content.blocks.count == 1)

        guard case .codeBlock(let language, let code) = content.blocks.first else {
            Issue.record("Expected code block")
            return
        }

        #expect(language == "swift")
        #expect(code.contains("let x = 1"))
    }

    @Test("Fenced code block without language parses correctly")
    func fencedCodeBlockWithoutLanguageParses() {
        let source = """
        ```
        plain code
        ```
        """
        let content = MarkdownContent(parsing: source)

        guard case .codeBlock(let language, let code) = content.blocks.first else {
            Issue.record("Expected code block")
            return
        }

        #expect(language == nil || language?.isEmpty == true)
        #expect(code.contains("plain code"))
    }

    // MARK: - List Parsing

    @Test("Unordered list parses correctly")
    func unorderedListParses() {
        let source = """
        - Item 1
        - Item 2
        - Item 3
        """
        let content = MarkdownContent(parsing: source)

        #expect(content.blocks.count == 1)

        guard case .unorderedList(let items) = content.blocks.first else {
            Issue.record("Expected unordered list")
            return
        }

        #expect(items.count == 3)
    }

    @Test("Ordered list parses correctly")
    func orderedListParses() {
        let source = """
        1. First
        2. Second
        3. Third
        """
        let content = MarkdownContent(parsing: source)

        guard case .orderedList(let start, let items) = content.blocks.first else {
            Issue.record("Expected ordered list")
            return
        }

        #expect(start == 1)
        #expect(items.count == 3)
    }

    // MARK: - Aside Parsing

    @Test("Blockquote parses as aside correctly")
    func asideParses() {
        let content = MarkdownContent(parsing: "> This is a quote")

        #expect(content.blocks.count == 1)

        guard case .aside(let kind, let blocks) = content.blocks.first else {
            Issue.record("Expected aside block")
            return
        }

        // Default kind for untagged blockquotes is .note
        #expect(kind == .note)
        #expect(blocks.count == 1)

        guard case .paragraph(let inlines) = blocks.first else {
            Issue.record("Expected paragraph inside aside")
            return
        }

        guard case .text(let text) = inlines.first else {
            Issue.record("Expected text inside aside paragraph")
            return
        }

        #expect(text == "This is a quote")
    }

    // MARK: - Link Parsing

    @Test("Inline link parses correctly")
    func inlineLinkParses() {
        let content = MarkdownContent(parsing: "Click [here](https://example.com)")

        guard case .paragraph(let inlines) = content.blocks.first else {
            Issue.record("Expected paragraph block")
            return
        }

        guard case .link(let destination, _, let linkContent) = inlines.last else {
            Issue.record("Expected link inline")
            return
        }

        #expect(destination == "https://example.com")

        guard case .text(let text) = linkContent.first else {
            Issue.record("Expected text inside link")
            return
        }

        #expect(text == "here")
    }

    // MARK: - Inline Code Parsing

    @Test("Inline code parses correctly")
    func inlineCodeParses() {
        let content = MarkdownContent(parsing: "Use `let x = 1` to declare")

        guard case .paragraph(let inlines) = content.blocks.first else {
            Issue.record("Expected paragraph block")
            return
        }

        guard case .code(let code) = inlines[1] else {
            Issue.record("Expected code inline")
            return
        }

        #expect(code == "let x = 1")
    }

    // MARK: - Thematic Break Parsing

    @Test("Thematic break parses correctly")
    func thematicBreakParses() {
        let content = MarkdownContent(parsing: "Above\n\n---\n\nBelow")

        #expect(content.blocks.count == 3)
        #expect(content.blocks[1] == .thematicBreak)
    }

    // MARK: - Mermaid Parsing

    @Test("Mermaid code block parses as mermaid block")
    func mermaidBlockParses() {
        let source = """
        ```mermaid
        graph LR
            A --> B
        ```
        """
        let content = MarkdownContent(parsing: source)

        #expect(content.blocks.count == 1)

        guard case .mermaid(let code) = content.blocks.first else {
            Issue.record("Expected mermaid block, got \(String(describing: content.blocks.first))")
            return
        }

        #expect(code.contains("graph LR"))
        #expect(code.contains("A --> B"))
    }

    @Test("Mermaid code block is distinguished from regular code block")
    func mermaidDistinguishedFromCodeBlock() {
        let mermaidSource = """
        ```mermaid
        flowchart TD
            Start --> End
        ```
        """
        let swiftSource = """
        ```swift
        let x = 1
        ```
        """

        let mermaidContent = MarkdownContent(parsing: mermaidSource)
        let swiftContent = MarkdownContent(parsing: swiftSource)

        // Mermaid should be parsed as .mermaid
        guard case .mermaid = mermaidContent.blocks.first else {
            Issue.record("Expected mermaid block for mermaid source")
            return
        }

        // Swift should be parsed as .codeBlock
        guard case .codeBlock = swiftContent.blocks.first else {
            Issue.record("Expected codeBlock for swift source")
            return
        }
    }

    @Test("Mermaid block preserves diagram content")
    func mermaidPreservesContent() {
        let diagramCode = """
        sequenceDiagram
            participant A as Alice
            participant B as Bob
            A->>B: Hello Bob!
            B-->>A: Hi Alice!
        """
        let source = """
        ```mermaid
        \(diagramCode)
        ```
        """
        let content = MarkdownContent(parsing: source)

        guard case .mermaid(let code) = content.blocks.first else {
            Issue.record("Expected mermaid block")
            return
        }

        #expect(code.contains("sequenceDiagram"))
        #expect(code.contains("participant A as Alice"))
        #expect(code.contains("A->>B: Hello Bob!"))
    }

    @Test("Mermaid block in mixed document")
    func mermaidInMixedDocument() {
        let source = """
        # Architecture

        Here is the system diagram:

        ```mermaid
        graph TD
            A[Client] --> B[Server]
        ```

        As shown above, the client connects to the server.
        """
        let content = MarkdownContent(parsing: source)

        #expect(content.blocks.count == 4) // heading, paragraph, mermaid, paragraph

        // Verify the mermaid block is in the right position
        guard case .mermaid(let code) = content.blocks[2] else {
            Issue.record("Expected mermaid block at index 2")
            return
        }

        #expect(code.contains("graph TD"))
    }
}
