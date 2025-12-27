import Testing
@testable import SwiftMarkdownView

/// Tests for Markdown link parsing
struct LinkTests {

    // MARK: - Basic Link Parsing

    @Test("Inline link parses with destination")
    func inlineLinkParsesWithDestination() {
        let source = "[Apple](https://apple.com)"
        let content = MarkdownContent(parsing: source)

        guard case .paragraph(let inlines) = content.blocks.first else {
            Issue.record("Expected paragraph block")
            return
        }

        guard case .link(let destination, _, let linkContent) = inlines.first else {
            Issue.record("Expected link inline")
            return
        }

        #expect(destination == "https://apple.com")
        #expect(linkContent.count >= 1)
    }

    @Test("Link with title parses correctly")
    func linkWithTitleParses() {
        let source = "[Apple](https://apple.com \"Apple's homepage\")"
        let content = MarkdownContent(parsing: source)

        guard case .paragraph(let inlines) = content.blocks.first else {
            Issue.record("Expected paragraph block")
            return
        }

        guard case .link(let destination, let title, _) = inlines.first else {
            Issue.record("Expected link inline")
            return
        }

        #expect(destination == "https://apple.com")
        #expect(title == "Apple's homepage")
    }

    @Test("Link with formatted content parses correctly")
    func linkWithFormattedContentParses() {
        let source = "[**Bold link**](https://example.com)"
        let content = MarkdownContent(parsing: source)

        guard case .paragraph(let inlines) = content.blocks.first else {
            Issue.record("Expected paragraph block")
            return
        }

        guard case .link(_, _, let linkContent) = inlines.first else {
            Issue.record("Expected link inline")
            return
        }

        // Content should contain strong
        #expect(linkContent.contains {
            if case .strong = $0 { return true }
            return false
        })
    }

    // MARK: - Multiple Links

    @Test("Multiple links in paragraph parse correctly")
    func multipleLinksInParagraph() {
        let source = "Visit [Apple](https://apple.com) or [Google](https://google.com)"
        let content = MarkdownContent(parsing: source)

        guard case .paragraph(let inlines) = content.blocks.first else {
            Issue.record("Expected paragraph block")
            return
        }

        let links = inlines.compactMap { inline -> String? in
            if case .link(let dest, _, _) = inline {
                return dest
            }
            return nil
        }

        #expect(links.count == 2)
        #expect(links.contains("https://apple.com"))
        #expect(links.contains("https://google.com"))
    }

    // MARK: - Link Types

    @Test("Email link parses correctly")
    func emailLinkParses() {
        let source = "[Contact](mailto:test@example.com)"
        let content = MarkdownContent(parsing: source)

        guard case .paragraph(let inlines) = content.blocks.first else {
            Issue.record("Expected paragraph block")
            return
        }

        guard case .link(let destination, _, _) = inlines.first else {
            Issue.record("Expected link inline")
            return
        }

        #expect(destination == "mailto:test@example.com")
    }

    @Test("Relative link parses correctly")
    func relativeLinkParses() {
        let source = "[Documentation](/docs/readme.md)"
        let content = MarkdownContent(parsing: source)

        guard case .paragraph(let inlines) = content.blocks.first else {
            Issue.record("Expected paragraph block")
            return
        }

        guard case .link(let destination, _, _) = inlines.first else {
            Issue.record("Expected link inline")
            return
        }

        #expect(destination == "/docs/readme.md")
    }

    // MARK: - Edge Cases

    @Test("Empty link destination parses correctly")
    func emptyLinkDestinationParses() {
        let source = "[Empty]()"
        let content = MarkdownContent(parsing: source)

        guard case .paragraph(let inlines) = content.blocks.first else {
            Issue.record("Expected paragraph block")
            return
        }

        guard case .link(let destination, _, _) = inlines.first else {
            Issue.record("Expected link inline")
            return
        }

        #expect(destination == "")
    }

    @Test("Link inside list item parses correctly")
    func linkInsideListItemParses() {
        let source = """
        - First item with [link](https://example.com)
        """
        let content = MarkdownContent(parsing: source)

        guard case .unorderedList(let items) = content.blocks.first else {
            Issue.record("Expected unordered list block")
            return
        }

        guard case .paragraph(let inlines) = items[0].blocks.first else {
            Issue.record("Expected paragraph in list item")
            return
        }

        let hasLink = inlines.contains {
            if case .link = $0 { return true }
            return false
        }

        #expect(hasLink)
    }
}
