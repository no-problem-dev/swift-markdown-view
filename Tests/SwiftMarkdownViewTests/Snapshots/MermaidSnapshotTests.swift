#if canImport(UIKit)
import Testing
import SwiftUI
import VisualTesting
@testable import SwiftMarkdownView

/// Snapshot tests for Mermaid diagram rendering.
///
/// Tests both the WebView-based rendering and the fallback view.
@SnapshotSuite("Mermaid")
@MainActor
struct MermaidSnapshotTests {

    init() { setupVisualTesting() }

    // MARK: - WebView Rendered Diagrams (async)

    // Async tests use the direct API since @ComponentSnapshot generates sync methods.

    @Test
    func flowchart() async {
        let view = MermaidDiagramView("""
        graph TD
            A[Start] --> B{Is it working?}
            B -->|Yes| C[Great!]
            B -->|No| D[Debug]
            D --> B
        """)
        .padding()

        try? await Task.sleep(for: .seconds(5.0))

        VisualTesting.assertComponentSnapshot(
            of: view,
            componentName: "Mermaid",
            stateName: "flowchart",
            size: CGSize(width: 400, height: 600),
            file: #filePath, line: #line
        )
    }

    @Test
    func sequenceDiagram() async {
        let view = MermaidDiagramView("""
        sequenceDiagram
            participant A as Alice
            participant B as Bob
            A->>B: Hello Bob!
            B-->>A: Hi Alice!
        """)
        .padding()

        try? await Task.sleep(for: .seconds(5.0))

        VisualTesting.assertComponentSnapshot(
            of: view,
            componentName: "Mermaid",
            stateName: "sequenceDiagram",
            size: CGSize(width: 400, height: 600),
            file: #filePath, line: #line
        )
    }

    @Test
    func complexFlowchartWithScrolling() async {
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
        .padding()

        try? await Task.sleep(for: .seconds(5.0))

        VisualTesting.assertComponentSnapshot(
            of: view,
            componentName: "Mermaid",
            stateName: "complexFlowchartWithScrolling",
            size: CGSize(width: 400, height: 600),
            file: #filePath, line: #line
        )
    }

    // MARK: - Fallback View Tests

    @ComponentSnapshot(width: 400, height: 600)
    func fallbackFlowchart() -> some View {
        MermaidFallbackView("""
        graph TD
            A[Start] --> B{Is it working?}
            B -->|Yes| C[Great!]
            B -->|No| D[Debug]
            D --> B
        """)
        .padding()
    }

    @ComponentSnapshot(width: 400, height: 600)
    func fallbackSequence() -> some View {
        MermaidFallbackView("""
        sequenceDiagram
            participant A as Alice
            participant B as Bob
            A->>B: Hello Bob!
            B-->>A: Hi Alice!
        """)
        .padding()
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
        .padding()

        try? await Task.sleep(for: .seconds(5.0))

        VisualTesting.assertComponentSnapshot(
            of: view,
            componentName: "Mermaid",
            stateName: "fullDocumentWithMermaid",
            size: CGSize(width: 400, height: 600),
            file: #filePath, line: #line
        )
    }
}
#endif
