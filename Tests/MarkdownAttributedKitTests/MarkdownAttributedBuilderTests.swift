import Testing
import Foundation
import MarkdownModel
@testable import MarkdownAttributedKit

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

private func build(_ source: String) -> NSAttributedString {
    MarkdownAttributedBuilder(theme: .default).build(MarkdownContent(parsing: source))
}

private extension NSAttributedString {
    func font(at index: Int) -> PlatformFont? {
        attribute(.font, at: index, effectiveRange: nil) as? PlatformFont
    }
    /// First character index where `substring` begins in the plain string.
    func index(of substring: String) -> Int? {
        (string as NSString).range(of: substring).location.nonNotFound
    }
}

private extension Int {
    var nonNotFound: Int? { self == NSNotFound ? nil : self }
}

private func isBold(_ font: PlatformFont?) -> Bool {
    guard let font else { return false }
    #if canImport(UIKit)
    return font.fontDescriptor.symbolicTraits.contains(.traitBold)
    #elseif canImport(AppKit)
    return font.fontDescriptor.symbolicTraits.contains(.bold)
    #endif
}

private func isItalic(_ font: PlatformFont?) -> Bool {
    guard let font else { return false }
    #if canImport(UIKit)
    return font.fontDescriptor.symbolicTraits.contains(.traitItalic)
    #elseif canImport(AppKit)
    return font.fontDescriptor.symbolicTraits.contains(.italic)
    #endif
}

@Suite("MarkdownAttributedBuilder — prose")
struct MarkdownAttributedBuilderTests {

    @Test("Whole document is a single continuous string (selection substrate)")
    func continuousString() {
        let result = build("""
        # Title

        Hello **world**

        - a
        - b
        """)
        let plain = result.string
        // One storage holds heading, paragraph, and list items in reading order.
        #expect(plain.contains("Title"))
        #expect(plain.contains("Hello world"))
        #expect(plain.contains("a"))
        #expect(plain.contains("b"))
        // No raw Markdown syntax leaks into the readable text.
        #expect(!plain.contains("#"))
        #expect(!plain.contains("**"))
        // Blocks are newline-separated, not concatenated.
        #expect(plain.contains("Title\n"))
        // No trailing newline.
        #expect(!plain.hasSuffix("\n"))
    }

    @Test("Heading uses an enlarged bold font")
    func headingFont() {
        let result = build("# Big")
        let font = result.font(at: 0)
        #expect(isBold(font))
        #expect((font?.pointSize ?? 0) > MarkdownTextTheme.default.baseFontSize)
    }

    @Test("Strong renders bold over exactly its content")
    func strongRange() throws {
        let result = build("a **b** c")
        let plain = result.string
        let boldIndex = try #require(result.index(of: "b"))
        #expect(isBold(result.font(at: boldIndex)))
        // The plain "a " before is not bold.
        let plainIndex = try #require(result.index(of: "a"))
        #expect(!isBold(result.font(at: plainIndex)))
        #expect(plain.contains("a b c"))
    }

    @Test("Emphasis renders italic")
    func emphasisItalic() throws {
        let result = build("x *y* z")
        let i = try #require(result.index(of: "y"))
        #expect(isItalic(result.font(at: i)))
    }

    @Test("Inline code uses a monospaced font with a background")
    func inlineCode() throws {
        let result = build("call `print()` now")
        let i = try #require(result.index(of: "print()"))
        let font = result.font(at: i)
        #expect(font?.fontDescriptor.symbolicTraits.contains(monoTrait) == true)
        let bg = result.attribute(.backgroundColor, at: i, effectiveRange: nil) as? PlatformColor
        #expect(bg != nil)
    }

    @Test("Link carries a URL attribute")
    func link() throws {
        let result = build("see [docs](https://example.com)")
        let i = try #require(result.index(of: "docs"))
        let url = result.attribute(.link, at: i, effectiveRange: nil) as? URL
        #expect(url == URL(string: "https://example.com"))
    }

    @Test("Unordered list items get bullet markers")
    func bulletMarkers() {
        let result = build("- one\n- two")
        #expect(result.string.contains("\u{2022}\tone"))
        #expect(result.string.contains("\u{2022}\ttwo"))
    }

    @Test("Ordered list items get numbered markers")
    func numberedMarkers() {
        let result = build("1. first\n2. second")
        #expect(result.string.contains("1.\tfirst"))
        #expect(result.string.contains("2.\tsecond"))
    }

    @Test("Task list items get checkbox markers")
    func taskMarkers() {
        let result = build("- [ ] todo\n- [x] done")
        #expect(result.string.contains("\u{2610}\ttodo"))
        #expect(result.string.contains("\u{2611}\tdone"))
    }

    @Test("Code block preserves code verbatim and is monospaced")
    func codeBlock() throws {
        let result = build("```swift\nlet x = 1\n```")
        #expect(result.string.contains("let x = 1"))
        let i = try #require(result.index(of: "let x"))
        #expect(result.font(at: i)?.fontDescriptor.symbolicTraits.contains(monoTrait) == true)
    }

    @Test("Empty input produces an empty string")
    func empty() {
        #expect(build("").string.isEmpty)
    }

    @Test("Code block range is tagged with a codeBlock decoration and language")
    func codeBlockDecoration() throws {
        let result = build("```swift\nlet x = 1\n```")
        let i = try #require(result.index(of: "let x"))
        let decoration = result.attribute(.markdownBlockDecoration, at: i, effectiveRange: nil) as? MarkdownBlockDecoration
        #expect(decoration?.kind == .codeBlock(language: "swift"))
        let language = result.attribute(.markdownCodeLanguage, at: i, effectiveRange: nil) as? String
        #expect(language == "swift")
    }

    @Test("Thematic break is tagged with a thematicBreak decoration")
    func thematicBreakDecoration() {
        let result = build("a\n\n---\n\nb")
        var found = false
        result.enumerateAttribute(.markdownBlockDecoration, in: NSRange(location: 0, length: result.length)) { value, _, _ in
            if (value as? MarkdownBlockDecoration)?.kind == .thematicBreak { found = true }
        }
        #expect(found)
    }

    @Test("Blockquote content is tagged with a blockQuote decoration")
    func blockQuoteDecoration() throws {
        let result = build("> quoted text")
        let i = try #require(result.index(of: "quoted"))
        let decoration = result.attribute(.markdownBlockDecoration, at: i, effectiveRange: nil) as? MarkdownBlockDecoration
        #expect(decoration?.kind == .blockQuote(level: 1))
    }
}

private struct StubAttachmentRenderer: MarkdownAttachmentRendering {
    func renderedImage(for kind: MarkdownAttachment.Kind, theme: MarkdownTextTheme) -> MarkdownRenderedImage? {
        MarkdownRenderedImage(image: PlatformImage(), size: CGSize(width: 10, height: 10))
    }
}

@Suite("MarkdownAttributedBuilder — attachments")
struct MarkdownAttachmentTests {

    @Test("Without a renderer, an image falls back to alt text carrying its source")
    func imageFallback() throws {
        let result = build("![a cat](https://x/c.png)")
        #expect(result.string.contains("[a cat]"))
        let i = try #require(result.index(of: "a cat"))
        let source = result.attribute(.markdownSource, at: i, effectiveRange: nil) as? String
        #expect(source == "![a cat](https://x/c.png)")
    }

    @Test("Without a renderer, inline math falls back to delimited source")
    func mathFallback() throws {
        let result = build("value $e=mc^2$ here")
        #expect(result.string.contains("$e=mc^2$"))
        let i = try #require(result.index(of: "e=mc^2"))
        let source = result.attribute(.markdownSource, at: i, effectiveRange: nil) as? String
        #expect(source == "$e=mc^2$")
    }

    @Test("With a renderer, an image becomes a single attachment character")
    func imageAttachment() throws {
        let builder = MarkdownAttributedBuilder(theme: .default, attachmentRenderer: StubAttachmentRenderer())
        let result = builder.build(MarkdownContent(parsing: "![cat](c.png)"))
        let i = try #require(result.index(of: "\u{FFFC}"))
        let attachment = result.attribute(.markdownAttachment, at: i, effectiveRange: nil) as? MarkdownAttachment
        #expect(attachment?.kind == .image(source: "c.png", alt: "cat"))
        #expect(result.attribute(.attachment, at: i, effectiveRange: nil) is NSTextAttachment)
    }

    @Test("With a renderer, inline math becomes an attachment carrying its source")
    func mathAttachment() throws {
        let builder = MarkdownAttributedBuilder(theme: .default, attachmentRenderer: StubAttachmentRenderer())
        let result = builder.build(MarkdownContent(parsing: "$x^2$"))
        let i = try #require(result.index(of: "\u{FFFC}"))
        let attachment = result.attribute(.markdownAttachment, at: i, effectiveRange: nil) as? MarkdownAttachment
        #expect(attachment?.kind == .inlineMath(latex: "x^2"))
        let source = result.attribute(.markdownSource, at: i, effectiveRange: nil) as? String
        #expect(source == "$x^2$")
    }
}

@Suite("MarkdownAttributedBuilder — tables")
struct MarkdownTableTests {

    private static let source = """
    | Name | Age |
    | --- | ---: |
    | Alice | 30 |
    | Bob | 25 |
    """

    @Test("Table cells are real, tab-separated, selectable text")
    func cellsAreText() {
        let result = build(Self.source)
        let plain = result.string
        #expect(plain.contains("Name\tAge"))
        #expect(plain.contains("Alice\t30"))
        #expect(plain.contains("Bob\t25"))
    }

    @Test("Header cells are bold")
    func headerBold() throws {
        let result = build(Self.source)
        let i = try #require(result.index(of: "Name"))
        #expect(isBold(result.font(at: i)))
        let body = try #require(result.index(of: "Alice"))
        #expect(!isBold(result.font(at: body)))
    }

    @Test("Table range is tagged with a table decoration")
    func tableDecoration() throws {
        let result = build(Self.source)
        let i = try #require(result.index(of: "Alice"))
        let decoration = result.attribute(.markdownBlockDecoration, at: i, effectiveRange: nil) as? MarkdownBlockDecoration
        #expect(decoration?.kind == .table(columns: 2))
    }

    @Test("Copy-as-Markdown source reconstructs the pipe table with alignment")
    func pipeSource() throws {
        let result = build(Self.source)
        let i = try #require(result.index(of: "Alice"))
        let source = result.attribute(.markdownSource, at: i, effectiveRange: nil) as? String
        let md = try #require(source)
        #expect(md.contains("| Name | Age |"))
        #expect(md.contains("| Alice | 30 |"))
        #expect(md.contains("---:")) // right alignment preserved
    }
}

@Suite("MarkdownSyntaxHighlighting")
struct MarkdownSyntaxHighlightingTests {

    @Test("Code regions expose language and code, excluding the separator")
    func regions() {
        let result = build("text\n\n```swift\nlet x = 1\n```\n\nmore")
        let regions = MarkdownSyntaxHighlighting.regions(in: result)
        #expect(regions.count == 1)
        #expect(regions.first?.language == "swift")
        #expect(regions.first?.code == "let x = 1")
        // The region length matches the code exactly (no trailing newline).
        #expect(regions.first?.range.length == ("let x = 1" as NSString).length)
    }

    @Test("Two code blocks yield two regions in document order")
    func multipleRegions() {
        let result = build("```\na\n```\n\n```py\nb\n```")
        let regions = MarkdownSyntaxHighlighting.regions(in: result)
        #expect(regions.count == 2)
        #expect(regions[0].language == nil)
        #expect(regions[1].language == "py")
    }

    @Test("Foreground colors transplant onto the storage at the region")
    func applyColors() throws {
        let result = build("```\nabc\n```")
        let storage = NSTextStorage(attributedString: result)
        let region = try #require(MarkdownSyntaxHighlighting.regions(in: storage).first)

        var highlighted = AttributedString("abc")
        let red = PlatformColor.red
        if let r = highlighted.range(of: "a") {
            highlighted[r].foregroundColor = red
        }
        let applied = MarkdownSyntaxHighlighting.applyForegroundColors(from: highlighted, to: storage, at: region.range)
        #expect(applied)
        let color = storage.attribute(.foregroundColor, at: region.range.location, effectiveRange: nil) as? PlatformColor
        #expect(color == red)
    }

    @Test("Length mismatch is a safe no-op")
    func lengthMismatch() throws {
        let result = build("```\nabc\n```")
        let storage = NSTextStorage(attributedString: result)
        let region = try #require(MarkdownSyntaxHighlighting.regions(in: storage).first)
        let applied = MarkdownSyntaxHighlighting.applyForegroundColors(from: AttributedString("different length"), to: storage, at: region.range)
        #expect(!applied)
    }
}

private var monoTrait: PlatformFontDescriptorSymbolicTraits {
    #if canImport(UIKit)
    return .traitMonoSpace
    #elseif canImport(AppKit)
    return .monoSpace
    #endif
}

#if canImport(UIKit)
private typealias PlatformFontDescriptorSymbolicTraits = UIFontDescriptor.SymbolicTraits
#elseif canImport(AppKit)
private typealias PlatformFontDescriptorSymbolicTraits = NSFontDescriptor.SymbolicTraits
#endif
