#if canImport(UIKit)
import Testing
import SwiftUI
import VisualTesting
@testable import SwiftMarkdownView

/// Snapshot tests for block-level Markdown elements.
///
/// Tests rendering of paragraphs, headings, lists, asides (callouts), and tables.
@SnapshotSuite("BlockElements")
@MainActor
struct BlockElementSnapshotTests {

    init() { setupVisualTesting() }

    // MARK: - Paragraph

    @ComponentSnapshot(width: 400, height: 600)
    func paragraph() -> some View {
        MarkdownView("This is a simple paragraph of text.")
            .padding()
    }

    // MARK: - Headings

    @ComponentSnapshot(width: 400, height: 600)
    func headings() -> some View {
        MarkdownView("""
        # Heading 1
        ## Heading 2
        ### Heading 3
        #### Heading 4
        ##### Heading 5
        ###### Heading 6
        """)
        .padding()
    }

    // MARK: - Lists

    @ComponentSnapshot(width: 400, height: 600)
    func unorderedList() -> some View {
        MarkdownView("""
        - First item
        - Second item
        - Third item
        """)
        .padding()
    }

    @ComponentSnapshot(width: 400, height: 600)
    func orderedList() -> some View {
        MarkdownView("""
        1. First item
        2. Second item
        3. Third item
        """)
        .padding()
    }

    @ComponentSnapshot(width: 400, height: 600)
    func taskList() -> some View {
        MarkdownView("""
        - [x] Complete setup
        - [x] Write documentation
        - [ ] Add tests
        - [ ] Deploy to production
        """)
        .padding()
    }

    // MARK: - Aside (Blockquote)

    @ComponentSnapshot(width: 400, height: 600)
    func aside() -> some View {
        MarkdownView("""
        > Note: This is a note aside.
        > It can span multiple lines.

        > Warning: This is a warning.

        > Tip: This is a helpful tip.
        """)
        .padding()
    }

    // MARK: - Table

    @ComponentSnapshot(width: 400, height: 600)
    func table() -> some View {
        MarkdownView("""
        | Feature | Status | Priority |
        |:--------|:------:|--------:|
        | Auth    | ✅     | High    |
        | API     | 🔄     | Medium  |
        | Tests   | ❌     | Low     |
        """)
        .padding()
    }

    // MARK: - Thematic Break

    @ComponentSnapshot(width: 400, height: 600)
    func thematicBreak() -> some View {
        MarkdownView("""
        First section

        ---

        Second section
        """)
        .padding()
    }
}
#endif
