#if canImport(UIKit)
import Testing
import SwiftUI
import VisualTesting
@testable import SwiftMarkdownView

/// Snapshot tests for inline Markdown elements.
///
/// Tests rendering of emphasis, strong, inline code, links, and strikethrough.
@SnapshotSuite("InlineElements")
@MainActor
struct InlineElementSnapshotTests {

    init() { setupVisualTesting() }

    // MARK: - Emphasis & Strong

    @ComponentSnapshot(width: 400, height: 600)
    func emphasisAndStrong() -> some View {
        MarkdownView("""
        This text has *emphasis* and **strong** formatting.
        You can also combine ***both***.
        """)
        .padding()
    }

    // MARK: - Inline Code

    @ComponentSnapshot(width: 400, height: 600)
    func inlineCode() -> some View {
        MarkdownView("""
        Use the `let` keyword to declare a constant.
        The `func` keyword defines a function.
        """)
        .padding()
    }

    // MARK: - Links

    @ComponentSnapshot(width: 400, height: 600)
    func links() -> some View {
        MarkdownView("""
        Visit [Apple](https://apple.com) for more info.
        Check the [documentation](https://docs.example.com "API Docs").
        """)
        .padding()
    }

    // MARK: - Strikethrough

    @ComponentSnapshot(width: 400, height: 600)
    func strikethrough() -> some View {
        MarkdownView("""
        This is ~~deleted text~~ with strikethrough.
        You can combine ~~strikethrough with **strong**~~ text.
        """)
        .padding()
    }

    // MARK: - Mixed Inline Elements

    @ComponentSnapshot(width: 400, height: 600)
    func mixedInline() -> some View {
        MarkdownView("""
        Check out the **[Swift documentation](https://swift.org)** for details.
        Use `async`/`await` for *asynchronous* code.
        """)
        .padding()
    }
}
#endif
