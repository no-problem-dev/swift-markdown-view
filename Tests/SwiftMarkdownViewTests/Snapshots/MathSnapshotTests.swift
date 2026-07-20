#if canImport(UIKit)
import Testing
import SwiftUI
import VisualTesting
@testable import SwiftMarkdownView
import SwiftMarkdownViewLaTeX

/// Snapshot tests for math rendering in Markdown.
///
/// Covers both the dependency-free fallback (PlainMathRenderer) and
/// the LaTeX integration module (LaTeXMathRenderer).
@Suite("Math Snapshots")
@MainActor
struct MathSnapshotTests {

    init() { setupVisualTesting() }

    private let snapshotSize = CGSize(width: 400, height: 300)

    // MARK: - LaTeX Renderer

    @Test
    func inlineInParagraph() {
        let view = MarkdownView(#"For $ax^2 + bx + c = 0$ with \(a \neq 0\), solutions exist."#)
            .markdownMathRenderer(LaTeXMathRenderer())
            .padding()

        VisualTesting.assertComponentSnapshot(
            of: view,
            componentName: "MarkdownMath",
            stateName: "latex-inline",
            size: snapshotSize,
            file: #filePath, line: #line
        )
    }

    @Test
    func displayBlock() {
        let view = MarkdownView("""
        The quadratic formula:

        $$x = \\frac{-b \\pm \\sqrt{b^2 - 4ac}}{2a}$$
        """)
        .markdownMathRenderer(LaTeXMathRenderer())
        .padding()

        VisualTesting.assertComponentSnapshot(
            of: view,
            componentName: "MarkdownMath",
            stateName: "latex-display",
            size: snapshotSize,
            file: #filePath, line: #line
        )
    }

    @Test
    func mixedDocument() {
        let view = MarkdownView("""
        ## Sum Formula

        With $n$ terms — but costing $5 each:

        ```math
        \\sum_{i=1}^{n} i = \\frac{n(n+1)}{2}
        ```

        **Bold with math: $e^{i\\pi}$ inside.**
        """)
        .markdownMathRenderer(LaTeXMathRenderer())
        .padding()

        VisualTesting.assertComponentSnapshot(
            of: view,
            componentName: "MarkdownMath",
            stateName: "latex-mixed",
            size: CGSize(width: 400, height: 420),
            file: #filePath, line: #line
        )
    }

    // MARK: - Plain Fallback (no LaTeX module)

    @Test
    func plainFallback() {
        let view = MarkdownView("""
        Inline $x^2$ and display:

        $$E = mc^2$$
        """)
        .padding()

        VisualTesting.assertComponentSnapshot(
            of: view,
            componentName: "MarkdownMath",
            stateName: "plain-fallback",
            size: snapshotSize,
            file: #filePath, line: #line
        )
    }

    // MARK: - renderMath Disabled

    @Test
    func renderMathDisabled() {
        let view = MarkdownView("""
        Inline $x^2$ and display:

        $$E = mc^2$$
        """)
        .markdownMathRenderer(LaTeXMathRenderer())
        .markdownRenderingOptions(MarkdownRenderingOptions(renderMath: false))
        .padding()

        VisualTesting.assertComponentSnapshot(
            of: view,
            componentName: "MarkdownMath",
            stateName: "math-disabled",
            size: snapshotSize,
            file: #filePath, line: #line
        )
    }
}
#endif
