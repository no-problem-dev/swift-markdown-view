import Testing
import SwiftUI
@testable import SwiftMarkdownView

/// Tests for MarkdownView rendering functionality
struct MarkdownViewTests {

    // MARK: - Basic Initialization

    @Test("MarkdownView initializes with string")
    func initWithString() {
        let view = MarkdownView("Hello, World!")

        // View should be created without throwing
        #expect(view.content.blocks.count == 1)
    }

    @Test("MarkdownView initializes with MarkdownContent")
    func initWithContent() {
        let content = MarkdownContent(parsing: "# Title")
        let view = MarkdownView(content)

        #expect(view.content.blocks.count == 1)
    }

    @Test("MarkdownView initializes with multiline markdown")
    func initWithMultilineMarkdown() {
        let source = """
        # Title

        This is a paragraph.

        - Item 1
        - Item 2
        """
        let view = MarkdownView(source)

        // Should have: heading, paragraph, list
        #expect(view.content.blocks.count == 3)
    }
}
