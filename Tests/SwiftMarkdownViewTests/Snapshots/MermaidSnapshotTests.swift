import Testing
import SwiftUI
@testable import SwiftMarkdownView

/// Snapshot tests for Mermaid diagram rendering.
///
/// Tests both the WebView-based rendering (macOS 26+) and the fallback view.
@Suite("Mermaid Snapshots")
@MainActor
struct MermaidSnapshotTests {

    // MARK: - WebView Rendered Diagrams (macOS 26+)

    @available(macOS 26.0, *)
    @Test
    func flowchart() async {
        let view = MermaidDiagramView("""
        graph TD
            A[Start] --> B{Is it working?}
            B -->|Yes| C[Great!]
            B -->|No| D[Debug]
            D --> B
        """)
        await SnapshotTestHelper.assertSnapshotAsync(of: view, delay: 5.0)
    }

    @available(macOS 26.0, *)
    @Test
    func sequenceDiagram() async {
        let view = MermaidDiagramView("""
        sequenceDiagram
            participant A as Alice
            participant B as Bob
            A->>B: Hello Bob!
            B-->>A: Hi Alice!
        """)
        await SnapshotTestHelper.assertSnapshotAsync(of: view, delay: 5.0)
    }

    @available(macOS 26.0, *)
    @Test
    func complexFlowchartWithScrolling() async {
        // Test a complex diagram that would overflow the viewport
        // This tests the scrollable container functionality
        let view = MermaidDiagramView("""
        graph LR
            A[Start] --> B[Step 1]
            B --> C[Step 2]
            C --> D[Step 3]
            D --> E[Step 4]
            E --> F[Step 5]
            F --> G[Step 6]
            G --> H[Step 7]
            H --> I[Step 8]
            I --> J[Step 9]
            J --> K[End]

            B --> L[Branch 1]
            L --> M[Sub 1]
            M --> N[Sub 2]
            N --> O[Sub 3]
            O --> P[Merge]
            P --> F
        """)
        await SnapshotTestHelper.assertSnapshotAsync(of: view, delay: 5.0)
    }

    // MARK: - Fallback View Tests

    @Test
    func fallbackFlowchart() {
        let view = MermaidFallbackView("""
        graph TD
            A[Start] --> B{Is it working?}
            B -->|Yes| C[Great!]
            B -->|No| D[Debug]
            D --> B
        """)
        SnapshotTestHelper.assertSnapshot(of: view)
    }

    @Test
    func fallbackSequence() {
        let view = MermaidFallbackView("""
        sequenceDiagram
            participant A as Alice
            participant B as Bob
            A->>B: Hello Bob!
            B-->>A: Hi Alice!
        """)
        SnapshotTestHelper.assertSnapshot(of: view)
    }

    // MARK: - Mixed Document with Mermaid

    @Test
    func documentWithMermaid() {
        // Test that mermaid blocks are correctly parsed in mixed documents
        let content = MarkdownContent(parsing: """
        # System Architecture

        The following diagram shows the data flow:

        ```mermaid
        graph LR
            User --> API
            API --> Database
            API --> Cache
        ```

        ## Components

        - **API**: REST endpoints
        - **Database**: PostgreSQL
        - **Cache**: Redis
        """)

        // Verify parsed structure: heading, paragraph, mermaid, heading, list
        #expect(content.blocks.count == 5)

        // Test that mermaid block is correctly identified
        if case .mermaid(let code) = content.blocks[2] {
            #expect(code.contains("graph LR"))
            #expect(code.contains("User --> API"))
        } else {
            Issue.record("Expected mermaid block at index 2")
        }
    }

    // MARK: - Full Document Rendering with Mermaid

    @available(macOS 26.0, *)
    @Test
    func fullDocumentWithMermaid() async {
        let view = MarkdownView("""
        # Architecture Overview

        ```mermaid
        graph LR
            User --> API
            API --> Database
        ```

        The diagram above shows the system flow.
        """)
        await SnapshotTestHelper.assertSnapshotAsync(of: view, delay: 5.0)
    }
}
