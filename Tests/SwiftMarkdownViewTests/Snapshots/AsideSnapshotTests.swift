#if canImport(UIKit)
import Testing
import SwiftUI
import VisualTesting
@testable import SwiftMarkdownView

/// Snapshot tests for Aside (callout/admonition) rendering.
///
/// Tests all AsideKind variants to ensure consistent visual appearance.
@SnapshotSuite("Aside")
@MainActor
struct AsideSnapshotTests {

    init() { setupVisualTesting() }

    // MARK: - Common Callouts

    @ComponentSnapshot(width: 400, height: 600)
    func noteAside() -> some View {
        MarkdownView("""
        > Note: This is a note aside with supplementary information.
        > It provides additional context that may be helpful.
        """)
        .padding()
    }

    @ComponentSnapshot(width: 400, height: 600)
    func tipAside() -> some View {
        MarkdownView("""
        > Tip: Here's a helpful tip for better productivity.
        > Try using keyboard shortcuts to save time.
        """)
        .padding()
    }

    @ComponentSnapshot(width: 400, height: 600)
    func importantAside() -> some View {
        MarkdownView("""
        > Important: This information is crucial for understanding.
        > Make sure to read this carefully before proceeding.
        """)
        .padding()
    }

    @ComponentSnapshot(width: 400, height: 600)
    func warningAside() -> some View {
        MarkdownView("""
        > Warning: This action cannot be undone.
        > Please backup your data before continuing.
        """)
        .padding()
    }

    @ComponentSnapshot(width: 400, height: 600)
    func experimentAside() -> some View {
        MarkdownView("""
        > Experiment: Try modifying the code to see what happens.
        > This is a great way to learn by doing.
        """)
        .padding()
    }

    // MARK: - Additional Callouts

    @ComponentSnapshot(width: 400, height: 600)
    func attentionAside() -> some View {
        MarkdownView("""
        > Attention: Please review this section carefully.
        """)
        .padding()
    }

    @ComponentSnapshot(width: 400, height: 600)
    func bugAside() -> some View {
        MarkdownView("""
        > Bug: There is a known issue with authentication on iOS 16.
        > A fix will be available in the next release.
        """)
        .padding()
    }

    @ComponentSnapshot(width: 400, height: 600)
    func todoAside() -> some View {
        MarkdownView("""
        > ToDo: Implement error handling for network failures.
        """)
        .padding()
    }

    @ComponentSnapshot(width: 400, height: 600)
    func seeAlsoAside() -> some View {
        MarkdownView("""
        > SeeAlso: Check the related documentation for more details.
        """)
        .padding()
    }

    @ComponentSnapshot(width: 400, height: 600)
    func throwsAside() -> some View {
        MarkdownView("""
        > Throws: `InvalidInputError` when the input parameter is nil.
        """)
        .padding()
    }

    @ComponentSnapshot(width: 400, height: 600)
    func remarkAside() -> some View {
        MarkdownView("""
        > Remark: This implementation follows the observer pattern.
        """)
        .padding()
    }

    @ComponentSnapshot(width: 400, height: 600)
    func preconditionAside() -> some View {
        MarkdownView("""
        > Precondition: The array must not be empty.
        """)
        .padding()
    }

    @ComponentSnapshot(width: 400, height: 600)
    func postconditionAside() -> some View {
        MarkdownView("""
        > Postcondition: The returned value is always positive.
        """)
        .padding()
    }

    @ComponentSnapshot(width: 400, height: 600)
    func complexityAside() -> some View {
        MarkdownView("""
        > Complexity: O(n log n) where n is the number of elements.
        """)
        .padding()
    }

    @ComponentSnapshot(width: 400, height: 600)
    func requiresAside() -> some View {
        MarkdownView("""
        > Requires: iOS 17.0 or later.
        """)
        .padding()
    }

    @ComponentSnapshot(width: 400, height: 600)
    func sinceAside() -> some View {
        MarkdownView("""
        > Since: Version 2.0
        """)
        .padding()
    }

    @ComponentSnapshot(width: 400, height: 600)
    func versionAside() -> some View {
        MarkdownView("""
        > Version: 1.0.0
        """)
        .padding()
    }

    @ComponentSnapshot(width: 400, height: 600)
    func authorAside() -> some View {
        MarkdownView("""
        > Author: John Doe
        """)
        .padding()
    }

    @ComponentSnapshot(width: 400, height: 600)
    func copyrightAside() -> some View {
        MarkdownView("""
        > Copyright: 2024 Example Corp. All rights reserved.
        """)
        .padding()
    }

    @ComponentSnapshot(width: 400, height: 600)
    func dateAside() -> some View {
        MarkdownView("""
        > Date: December 2024
        """)
        .padding()
    }

    @ComponentSnapshot(width: 400, height: 600)
    func invariantAside() -> some View {
        MarkdownView("""
        > Invariant: The count is always non-negative.
        """)
        .padding()
    }

    @ComponentSnapshot(width: 400, height: 600)
    func mutatingVariantAside() -> some View {
        MarkdownView("""
        > MutatingVariant: Use `sort()` for in-place sorting.
        """)
        .padding()
    }

    @ComponentSnapshot(width: 400, height: 600)
    func nonMutatingVariantAside() -> some View {
        MarkdownView("""
        > NonMutatingVariant: Use `sorted()` to get a new sorted array.
        """)
        .padding()
    }

    // MARK: - Custom Aside

    @ComponentSnapshot(width: 400, height: 600)
    func customAside() -> some View {
        MarkdownView("""
        > MyCustomTag: This is a custom aside type.
        """)
        .padding()
    }

    // MARK: - Regular Blockquote (defaults to Note)

    @ComponentSnapshot(width: 400, height: 600)
    func regularBlockquoteAsNote() -> some View {
        MarkdownView("""
        > This is a regular blockquote without a tag.
        > It defaults to the Note aside kind.
        """)
        .padding()
    }

    // MARK: - Complex Aside Content

    @ComponentSnapshot(width: 400, height: 600)
    func asideWithFormattedContent() -> some View {
        MarkdownView("""
        > Note: This aside contains **bold** and *italic* text.
        > It also has `inline code` and a [link](https://example.com).
        """)
        .padding()
    }

    @ComponentSnapshot(width: 400, height: 600)
    func asideWithList() -> some View {
        MarkdownView("""
        > Tip: Follow these steps:
        >
        > - First, install dependencies
        > - Then, configure settings
        > - Finally, run the application
        """)
        .padding()
    }

    @ComponentSnapshot(width: 400, height: 600)
    func asideWithCodeBlock() -> some View {
        MarkdownView("""
        > Important: Use this code pattern:
        >
        > ```swift
        > let result = try await fetchData()
        > ```
        """)
        .padding()
    }

    // MARK: - All Common Asides Together

    @ComponentSnapshot(width: 400, height: 600)
    func allCommonAsides() -> some View {
        MarkdownView("""
        > Note: This is a note.

        > Tip: This is a tip.

        > Important: This is important.

        > Warning: This is a warning.

        > Experiment: This is an experiment.
        """)
        .padding()
    }
}
#endif
