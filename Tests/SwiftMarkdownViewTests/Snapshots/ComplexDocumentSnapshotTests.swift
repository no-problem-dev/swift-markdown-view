import Testing
import SwiftUI
@testable import SwiftMarkdownView

/// Snapshot tests for complex multi-element Markdown documents.
///
/// Tests rendering of AI-style responses and mixed content documents.
@Suite("Complex Document Snapshots")
@MainActor
struct ComplexDocumentSnapshotTests {

    // MARK: - AI Response Style

    @Test
    func aiResponse() {
        let view = MarkdownView("""
        # API Response

        Here's how to implement the feature:

        ## Step 1: Create the Model

        ```swift
        struct User: Codable {
            let id: UUID
            let name: String
        }
        ```

        ## Step 2: Implement the Service

        The service should:

        - Handle authentication
        - Manage API calls
        - Cache responses

        > **Note**: Make sure to handle errors appropriately.

        For more details, see the [documentation](https://example.com).
        """)
        SnapshotTestHelper.assertSnapshot(of: view)
    }

    // MARK: - README Style

    @Test
    func readmeStyle() {
        let view = MarkdownView("""
        # SwiftMarkdownView

        A SwiftUI-native Markdown rendering library.

        ## Features

        - [x] Block elements (paragraphs, headings, lists)
        - [x] Inline elements (bold, italic, code)
        - [x] Syntax highlighting for 15+ languages
        - [ ] LaTeX support (coming soon)

        ## Installation

        Add to your `Package.swift`:

        ```swift
        dependencies: [
            .package(url: "https://github.com/example/swift-markdown-view", from: "1.0.0")
        ]
        ```

        ## Usage

        ```swift
        import SwiftMarkdownView

        struct ContentView: View {
            var body: some View {
                MarkdownView("# Hello, World!")
            }
        }
        ```

        ---

        MIT License
        """)
        SnapshotTestHelper.assertSnapshot(of: view)
    }

    // MARK: - Technical Documentation

    @Test
    func technicalDoc() {
        let view = MarkdownView("""
        ## API Reference

        ### `MarkdownView`

        | Parameter | Type | Description |
        |-----------|------|-------------|
        | source | `String` | The Markdown source |
        | content | `MarkdownContent` | Pre-parsed content |

        > **Important**: Always use pre-parsed content for performance-critical scenarios.

        Example usage:

        ```swift
        let content = MarkdownContent(parsing: source)
        MarkdownView(content)
        ```
        """)
        SnapshotTestHelper.assertSnapshot(of: view)
    }
}
