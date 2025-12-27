import Testing
import SwiftUI
@testable import SwiftMarkdownView

/// Snapshot tests for inline Markdown elements.
///
/// Tests rendering of emphasis, strong, inline code, links, and strikethrough.
@Suite("Inline Element Snapshots")
@MainActor
struct InlineElementSnapshotTests {

    // MARK: - Emphasis & Strong

    @Test
    func emphasisAndStrong() {
        let view = MarkdownView("""
        This text has *emphasis* and **strong** formatting.
        You can also combine ***both***.
        """)
        SnapshotTestHelper.assertSnapshot(of: view)
    }

    // MARK: - Inline Code

    @Test
    func inlineCode() {
        let view = MarkdownView("""
        Use the `let` keyword to declare a constant.
        The `func` keyword defines a function.
        """)
        SnapshotTestHelper.assertSnapshot(of: view)
    }

    // MARK: - Links

    @Test
    func links() {
        let view = MarkdownView("""
        Visit [Apple](https://apple.com) for more info.
        Check the [documentation](https://docs.example.com "API Docs").
        """)
        SnapshotTestHelper.assertSnapshot(of: view)
    }

    // MARK: - Strikethrough

    @Test
    func strikethrough() {
        let view = MarkdownView("""
        This is ~~deleted text~~ with strikethrough.
        You can combine ~~strikethrough with **strong**~~ text.
        """)
        SnapshotTestHelper.assertSnapshot(of: view)
    }

    // MARK: - Mixed Inline Elements

    @Test
    func mixedInline() {
        let view = MarkdownView("""
        Check out the **[Swift documentation](https://swift.org)** for details.
        Use `async`/`await` for *asynchronous* code.
        """)
        SnapshotTestHelper.assertSnapshot(of: view)
    }
}
