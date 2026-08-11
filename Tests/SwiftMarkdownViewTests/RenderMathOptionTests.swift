#if os(iOS) || os(macOS)
import Testing
import SwiftUI
import Foundation
@testable import SwiftMarkdownView
@testable import MarkdownAttributedKit

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// Draws every kind of attachment, so a kind that comes back empty is a suppression and not a
/// renderer that had nothing to say.
private struct AlwaysRenderingAttachmentRenderer: MarkdownAttachmentRendering {
    func renderedImage(for kind: MarkdownAttachment.Kind, theme: MarkdownTextTheme) -> MarkdownRenderedImage? {
        MarkdownRenderedImage(image: PlatformImage(), size: CGSize(width: 10, height: 10))
    }
}

/// What `renderMath` does to a rendered document.
///
/// The option used to be read by ``MathText`` alone: a ``MarkdownView`` typeset its math through
/// the attachment renderer no matter what was set, so `renderMath: false` changed nothing on
/// screen. What is pinned here is the decision the view now applies — with math off the builder
/// receives a renderer that refuses formulas, and everything else still gets drawn.
@Suite("renderMath option")
struct RenderMathOptionTests {

    private static let source = """
    Inline $x^2$ and display:

    $$E = mc^2$$
    """

    private func built(_ options: MarkdownRenderingOptions) -> NSAttributedString {
        MarkdownAttributedBuilder(
            theme: .default,
            attachmentRenderer: options.attachmentRenderer(wrapping: AlwaysRenderingAttachmentRenderer())
        )
        .build(MarkdownContent(parsing: Self.source))
    }

    @Test("On by default, formulas become attachment characters")
    func mathIsTypesetByDefault() {
        let result = built(.default)
        // One attachment character for the inline formula, one for the display block.
        #expect(result.string.filter { $0 == "\u{FFFC}" }.count == 2)
        #expect(!result.string.contains("$x^2$"))
    }

    @Test("Off, formulas are left standing as their LaTeX source")
    func mathIsLeftAsSource() {
        let result = built(MarkdownRenderingOptions(renderMath: false))
        #expect(result.string.contains("$x^2$"))
        #expect(result.string.contains("E = mc^2"))
        #expect(!result.string.contains("\u{FFFC}"))
    }

    @Test("Off, only math is refused — images and Mermaid still render")
    func onlyMathIsSuppressed() {
        let renderer = MarkdownRenderingOptions(renderMath: false)
            .attachmentRenderer(wrapping: AlwaysRenderingAttachmentRenderer())

        #expect(renderer.renderedImage(for: .inlineMath(latex: "x^2"), theme: .default) == nil)
        #expect(renderer.renderedImage(for: .displayMath(latex: "E = mc^2"), theme: .default) == nil)
        #expect(renderer.renderedImage(for: .image(source: "c.png", alt: "cat"), theme: .default) != nil)
        #expect(renderer.renderedImage(for: .mermaid(source: "graph TD;"), theme: .default) != nil)
    }

    @Test("On, the renderer in the environment is handed through untouched")
    func enabledOptionsDoNotWrap() {
        let base = AlwaysRenderingAttachmentRenderer()
        let renderer = MarkdownRenderingOptions.default.attachmentRenderer(wrapping: base)

        #expect(renderer is AlwaysRenderingAttachmentRenderer)
    }
}
#endif
