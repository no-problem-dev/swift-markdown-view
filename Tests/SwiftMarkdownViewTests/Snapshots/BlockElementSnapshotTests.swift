import Testing
import SwiftUI
@testable import SwiftMarkdownView

/// Snapshot tests for block-level Markdown elements.
///
/// Tests rendering of paragraphs, headings, lists, asides (callouts), and tables.
@Suite("Block Element Snapshots")
@MainActor
struct BlockElementSnapshotTests {

    // MARK: - Paragraph

    @Test
    func paragraph() {
        let view = MarkdownView("This is a simple paragraph of text.")
        SnapshotTestHelper.assertSnapshot(of: view)
    }

    // MARK: - Headings

    @Test
    func headings() {
        let view = MarkdownView("""
        # Heading 1
        ## Heading 2
        ### Heading 3
        #### Heading 4
        ##### Heading 5
        ###### Heading 6
        """)
        SnapshotTestHelper.assertSnapshot(of: view)
    }

    // MARK: - Lists

    @Test
    func unorderedList() {
        let view = MarkdownView("""
        - First item
        - Second item
        - Third item
        """)
        SnapshotTestHelper.assertSnapshot(of: view)
    }

    @Test
    func orderedList() {
        let view = MarkdownView("""
        1. First item
        2. Second item
        3. Third item
        """)
        SnapshotTestHelper.assertSnapshot(of: view)
    }

    @Test
    func taskList() {
        let view = MarkdownView("""
        - [x] Complete setup
        - [x] Write documentation
        - [ ] Add tests
        - [ ] Deploy to production
        """)
        SnapshotTestHelper.assertSnapshot(of: view)
    }

    // MARK: - Aside (Blockquote)

    @Test
    func aside() {
        let view = MarkdownView("""
        > Note: This is a note aside.
        > It can span multiple lines.

        > Warning: This is a warning.

        > Tip: This is a helpful tip.
        """)
        SnapshotTestHelper.assertSnapshot(of: view)
    }

    // MARK: - Table

    @Test
    func table() {
        let view = MarkdownView("""
        | Feature | Status | Priority |
        |:--------|:------:|--------:|
        | Auth    | ✅     | High    |
        | API     | 🔄     | Medium  |
        | Tests   | ❌     | Low     |
        """)
        SnapshotTestHelper.assertSnapshot(of: view)
    }

    // MARK: - Thematic Break

    @Test
    func thematicBreak() {
        let view = MarkdownView("""
        First section

        ---

        Second section
        """)
        SnapshotTestHelper.assertSnapshot(of: view)
    }
}
