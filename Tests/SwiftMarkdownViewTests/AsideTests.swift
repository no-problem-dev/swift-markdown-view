import Testing
@testable import SwiftMarkdownView

/// Tests for Markdown aside (callout/admonition) parsing
struct AsideTests {

    // MARK: - Basic Aside Kind Parsing

    @Test("Note aside parses correctly")
    func noteAsideParses() {
        let source = "> Note: This is a note"
        let content = MarkdownContent(parsing: source)

        #expect(content.blocks.count == 1)

        guard case .aside(let kind, let blocks) = content.blocks.first else {
            Issue.record("Expected aside block")
            return
        }

        #expect(kind == .note)
        #expect(blocks.count == 1)
    }

    @Test("Warning aside parses correctly")
    func warningAsideParses() {
        let source = "> Warning: Be careful!"
        let content = MarkdownContent(parsing: source)

        guard case .aside(let kind, _) = content.blocks.first else {
            Issue.record("Expected aside block")
            return
        }

        #expect(kind == .warning)
    }

    @Test("Tip aside parses correctly")
    func tipAsideParses() {
        let source = "> Tip: Here's a helpful tip"
        let content = MarkdownContent(parsing: source)

        guard case .aside(let kind, _) = content.blocks.first else {
            Issue.record("Expected aside block")
            return
        }

        #expect(kind == .tip)
    }

    @Test("Important aside parses correctly")
    func importantAsideParses() {
        let source = "> Important: Don't forget this!"
        let content = MarkdownContent(parsing: source)

        guard case .aside(let kind, _) = content.blocks.first else {
            Issue.record("Expected aside block")
            return
        }

        #expect(kind == .important)
    }

    @Test("Experiment aside parses correctly")
    func experimentAsideParses() {
        let source = "> Experiment: Try this approach"
        let content = MarkdownContent(parsing: source)

        guard case .aside(let kind, _) = content.blocks.first else {
            Issue.record("Expected aside block")
            return
        }

        #expect(kind == .experiment)
    }

    // MARK: - Default Behavior

    @Test("Regular blockquote without tag becomes note aside")
    func regularBlockquoteBecomesNote() {
        let source = "> Just a regular quote"
        let content = MarkdownContent(parsing: source)

        guard case .aside(let kind, let blocks) = content.blocks.first else {
            Issue.record("Expected aside block")
            return
        }

        #expect(kind == .note)

        guard case .paragraph(let inlines) = blocks.first else {
            Issue.record("Expected paragraph in aside")
            return
        }

        guard case .text(let text) = inlines.first else {
            Issue.record("Expected text in paragraph")
            return
        }

        #expect(text == "Just a regular quote")
    }

    // MARK: - Custom Aside Kind

    @Test("Custom aside kind parses correctly")
    func customAsideParses() {
        let source = "> MyCustomTag: Custom content"
        let content = MarkdownContent(parsing: source)

        guard case .aside(let kind, _) = content.blocks.first else {
            Issue.record("Expected aside block")
            return
        }

        #expect(kind == .custom("MyCustomTag"))
    }

    // MARK: - Multi-line Content

    @Test("Multi-line aside preserves content")
    func multiLineAsideParses() {
        let source = """
        > Warning: This is a warning
        > that spans multiple lines
        > with additional content.
        """
        let content = MarkdownContent(parsing: source)

        guard case .aside(let kind, let blocks) = content.blocks.first else {
            Issue.record("Expected aside block")
            return
        }

        #expect(kind == .warning)
        #expect(!blocks.isEmpty)
    }

    @Test("Nested content in aside parses correctly")
    func nestedAsideParses() {
        let source = """
        > Tip: Here's a tip with a list:
        >
        > - First point
        > - Second point
        """
        let content = MarkdownContent(parsing: source)

        guard case .aside(let kind, let blocks) = content.blocks.first else {
            Issue.record("Expected aside block")
            return
        }

        #expect(kind == .tip)
        #expect(blocks.count == 2) // paragraph + unordered list
    }

    // MARK: - AsideKind Tests

    @Test("AsideKind displayName returns correct values")
    func asideKindDisplayNames() {
        #expect(AsideKind.note.displayName == "Note")
        #expect(AsideKind.tip.displayName == "Tip")
        #expect(AsideKind.warning.displayName == "Warning")
        #expect(AsideKind.important.displayName == "Important")
        #expect(AsideKind.seeAlso.displayName == "See Also")
        #expect(AsideKind.todo.displayName == "To Do")
        #expect(AsideKind.mutatingVariant.displayName == "Mutating Variant")
        #expect(AsideKind.nonMutatingVariant.displayName == "Non-Mutating Variant")
        #expect(AsideKind.custom("Test").displayName == "Test")
    }

    @Test("AsideKind rawValue initialization is case-insensitive")
    func asideKindRawValueCaseInsensitive() {
        #expect(AsideKind(rawValue: "note") == .note)
        #expect(AsideKind(rawValue: "NOTE") == .note)
        #expect(AsideKind(rawValue: "Note") == .note)
        #expect(AsideKind(rawValue: "warning") == .warning)
        #expect(AsideKind(rawValue: "WARNING") == .warning)
    }

    // MARK: - Additional Aside Kinds

    @Test("Bug aside parses correctly")
    func bugAsideParses() {
        let source = "> Bug: Known issue with authentication"
        let content = MarkdownContent(parsing: source)

        guard case .aside(let kind, _) = content.blocks.first else {
            Issue.record("Expected aside block")
            return
        }

        #expect(kind == .bug)
    }

    @Test("ToDo aside parses correctly")
    func todoAsideParses() {
        let source = "> ToDo: Implement this feature"
        let content = MarkdownContent(parsing: source)

        guard case .aside(let kind, _) = content.blocks.first else {
            Issue.record("Expected aside block")
            return
        }

        #expect(kind == .todo)
    }

    @Test("SeeAlso aside parses correctly")
    func seeAlsoAsideParses() {
        let source = "> SeeAlso: Related documentation"
        let content = MarkdownContent(parsing: source)

        guard case .aside(let kind, _) = content.blocks.first else {
            Issue.record("Expected aside block")
            return
        }

        #expect(kind == .seeAlso)
    }

    @Test("Throws aside parses correctly")
    func throwsAsideParses() {
        let source = "> Throws: InvalidInputError when input is nil"
        let content = MarkdownContent(parsing: source)

        guard case .aside(let kind, _) = content.blocks.first else {
            Issue.record("Expected aside block")
            return
        }

        #expect(kind == .throws)
    }

    // MARK: - Content Formatting

    @Test("Aside with formatted content parses correctly")
    func asideWithFormattedContent() {
        let source = "> Note: This is **bold** and *italic* text"
        let content = MarkdownContent(parsing: source)

        guard case .aside(_, let blocks) = content.blocks.first else {
            Issue.record("Expected aside block")
            return
        }

        guard case .paragraph(let inlines) = blocks.first else {
            Issue.record("Expected paragraph in aside")
            return
        }

        // Should contain formatted content
        let hasStrong = inlines.contains { if case .strong = $0 { return true }; return false }
        let hasEmphasis = inlines.contains { if case .emphasis = $0 { return true }; return false }

        #expect(hasStrong)
        #expect(hasEmphasis)
    }

    @Test("Aside with code block parses correctly")
    func asideWithCodeBlock() {
        let source = """
        > Tip: Use this code:
        >
        > ```swift
        > let x = 1
        > ```
        """
        let content = MarkdownContent(parsing: source)

        guard case .aside(let kind, let blocks) = content.blocks.first else {
            Issue.record("Expected aside block")
            return
        }

        #expect(kind == .tip)

        let hasCodeBlock = blocks.contains {
            if case .codeBlock = $0 { return true }
            return false
        }

        #expect(hasCodeBlock)
    }
}
