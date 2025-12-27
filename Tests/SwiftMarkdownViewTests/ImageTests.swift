import Testing
@testable import SwiftMarkdownView

/// Tests for Markdown image parsing
struct ImageTests {

    // MARK: - Basic Image Parsing

    @Test("Image with source parses correctly")
    func imageWithSourceParses() {
        let source = "![Alt text](https://example.com/image.png)"
        let content = MarkdownContent(parsing: source)

        guard case .paragraph(let inlines) = content.blocks.first else {
            Issue.record("Expected paragraph block")
            return
        }

        guard case .image(let src, let alt, _) = inlines.first else {
            Issue.record("Expected image inline")
            return
        }

        #expect(src == "https://example.com/image.png")
        #expect(alt == "Alt text")
    }

    @Test("Image with title parses correctly")
    func imageWithTitleParses() {
        let source = "![Photo](https://example.com/photo.jpg \"A beautiful photo\")"
        let content = MarkdownContent(parsing: source)

        guard case .paragraph(let inlines) = content.blocks.first else {
            Issue.record("Expected paragraph block")
            return
        }

        guard case .image(_, _, let title) = inlines.first else {
            Issue.record("Expected image inline")
            return
        }

        #expect(title == "A beautiful photo")
    }

    @Test("Image without alt text parses correctly")
    func imageWithoutAltParses() {
        let source = "![](https://example.com/image.png)"
        let content = MarkdownContent(parsing: source)

        guard case .paragraph(let inlines) = content.blocks.first else {
            Issue.record("Expected paragraph block")
            return
        }

        guard case .image(let src, let alt, _) = inlines.first else {
            Issue.record("Expected image inline")
            return
        }

        #expect(src == "https://example.com/image.png")
        #expect(alt == "")
    }

    // MARK: - Image Contexts

    @Test("Image in paragraph with text parses correctly")
    func imageInParagraphWithText() {
        let source = "Check out this image: ![Photo](https://example.com/photo.jpg)"
        let content = MarkdownContent(parsing: source)

        guard case .paragraph(let inlines) = content.blocks.first else {
            Issue.record("Expected paragraph block")
            return
        }

        let hasText = inlines.contains { if case .text = $0 { return true }; return false }
        let hasImage = inlines.contains { if case .image = $0 { return true }; return false }

        #expect(hasText)
        #expect(hasImage)
    }

    @Test("Multiple images parse correctly")
    func multipleImagesInParagraph() {
        let source = "![First](a.png) and ![Second](b.png)"
        let content = MarkdownContent(parsing: source)

        guard case .paragraph(let inlines) = content.blocks.first else {
            Issue.record("Expected paragraph block")
            return
        }

        let images = inlines.compactMap { inline -> String? in
            if case .image(let src, _, _) = inline {
                return src
            }
            return nil
        }

        #expect(images.count == 2)
        #expect(images.contains("a.png"))
        #expect(images.contains("b.png"))
    }

    // MARK: - Image URL Types

    @Test("Relative image path parses correctly")
    func relativeImagePathParses() {
        let source = "![Local](./images/photo.png)"
        let content = MarkdownContent(parsing: source)

        guard case .paragraph(let inlines) = content.blocks.first else {
            Issue.record("Expected paragraph block")
            return
        }

        guard case .image(let src, _, _) = inlines.first else {
            Issue.record("Expected image inline")
            return
        }

        #expect(src == "./images/photo.png")
    }

    @Test("Data URI image parses correctly")
    func dataURIImageParses() {
        let source = "![Data](data:image/png;base64,iVBORw0KGgo=)"
        let content = MarkdownContent(parsing: source)

        guard case .paragraph(let inlines) = content.blocks.first else {
            Issue.record("Expected paragraph block")
            return
        }

        guard case .image(let src, _, _) = inlines.first else {
            Issue.record("Expected image inline")
            return
        }

        #expect(src.hasPrefix("data:image/png"))
    }

    // MARK: - Edge Cases

    @Test("Image inside link parses correctly")
    func imageInsideLinkParses() {
        let source = "[![Alt](image.png)](https://example.com)"
        let content = MarkdownContent(parsing: source)

        guard case .paragraph(let inlines) = content.blocks.first else {
            Issue.record("Expected paragraph block")
            return
        }

        guard case .link(let dest, _, let linkContent) = inlines.first else {
            Issue.record("Expected link inline")
            return
        }

        #expect(dest == "https://example.com")

        let hasImage = linkContent.contains {
            if case .image = $0 { return true }
            return false
        }
        #expect(hasImage)
    }
}
