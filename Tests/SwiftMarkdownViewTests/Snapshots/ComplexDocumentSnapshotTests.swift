#if canImport(UIKit)
import Testing
import SwiftUI
import VisualTesting
@testable import SwiftMarkdownView
import SwiftMarkdownViewHighlightJS

/// Snapshot tests for complex multi-element Markdown documents.
///
/// Tests rendering of AI-style responses and mixed content documents
/// using HighlightJS-based syntax highlighter for accurate code highlighting.
/// Uses the direct API since async delay is needed for syntax highlighting.
@Suite("Complex Document Snapshots")
@MainActor
struct ComplexDocumentSnapshotTests {

    init() { setupVisualTesting() }

    /// Light mode highlighter for white background snapshots.
    private let highlighter = HighlightJSSyntaxHighlighter(theme: .a11y, colorMode: .light)

    /// Delay for async syntax highlighting to complete.
    private let highlightDelay: TimeInterval = 1.0

    /// Default size for complex document snapshots.
    private let snapshotSize = CGSize(width: 400, height: 600)

    // MARK: - AI Response Style

    @Test
    func aiResponse() async {
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
        .syntaxHighlighter(highlighter)
        .padding()

        try? await Task.sleep(for: .seconds(highlightDelay))

        VisualTesting.assertComponentSnapshot(
            of: view,
            componentName: "ComplexDocument",
            stateName: "aiResponse",
            size: snapshotSize,
            file: #filePath, line: #line
        )
    }

    // MARK: - README Style

    @Test
    func readmeStyle() async {
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
        .syntaxHighlighter(highlighter)
        .padding()

        try? await Task.sleep(for: .seconds(highlightDelay))

        VisualTesting.assertComponentSnapshot(
            of: view,
            componentName: "ComplexDocument",
            stateName: "readmeStyle",
            size: snapshotSize,
            file: #filePath, line: #line
        )
    }

    // MARK: - Technical Documentation

    @Test
    func technicalDoc() async {
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
        .syntaxHighlighter(highlighter)
        .padding()

        try? await Task.sleep(for: .seconds(highlightDelay))

        VisualTesting.assertComponentSnapshot(
            of: view,
            componentName: "ComplexDocument",
            stateName: "technicalDoc",
            size: snapshotSize,
            file: #filePath, line: #line
        )
    }
}
#endif
