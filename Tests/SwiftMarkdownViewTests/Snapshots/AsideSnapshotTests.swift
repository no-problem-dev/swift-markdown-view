import Testing
import SwiftUI
@testable import SwiftMarkdownView

/// Snapshot tests for Aside (callout/admonition) rendering.
///
/// Tests all AsideKind variants to ensure consistent visual appearance.
@Suite("Aside Snapshots")
@MainActor
struct AsideSnapshotTests {

    // MARK: - Common Callouts

    @Test
    func noteAside() {
        let view = MarkdownView("""
        > Note: This is a note aside with supplementary information.
        > It provides additional context that may be helpful.
        """)
        SnapshotTestHelper.assertSnapshot(of: view)
    }

    @Test
    func tipAside() {
        let view = MarkdownView("""
        > Tip: Here's a helpful tip for better productivity.
        > Try using keyboard shortcuts to save time.
        """)
        SnapshotTestHelper.assertSnapshot(of: view)
    }

    @Test
    func importantAside() {
        let view = MarkdownView("""
        > Important: This information is crucial for understanding.
        > Make sure to read this carefully before proceeding.
        """)
        SnapshotTestHelper.assertSnapshot(of: view)
    }

    @Test
    func warningAside() {
        let view = MarkdownView("""
        > Warning: This action cannot be undone.
        > Please backup your data before continuing.
        """)
        SnapshotTestHelper.assertSnapshot(of: view)
    }

    @Test
    func experimentAside() {
        let view = MarkdownView("""
        > Experiment: Try modifying the code to see what happens.
        > This is a great way to learn by doing.
        """)
        SnapshotTestHelper.assertSnapshot(of: view)
    }

    // MARK: - Additional Callouts

    @Test
    func attentionAside() {
        let view = MarkdownView("""
        > Attention: Please review this section carefully.
        """)
        SnapshotTestHelper.assertSnapshot(of: view)
    }

    @Test
    func bugAside() {
        let view = MarkdownView("""
        > Bug: There is a known issue with authentication on iOS 16.
        > A fix will be available in the next release.
        """)
        SnapshotTestHelper.assertSnapshot(of: view)
    }

    @Test
    func todoAside() {
        let view = MarkdownView("""
        > ToDo: Implement error handling for network failures.
        """)
        SnapshotTestHelper.assertSnapshot(of: view)
    }

    @Test
    func seeAlsoAside() {
        let view = MarkdownView("""
        > SeeAlso: Check the related documentation for more details.
        """)
        SnapshotTestHelper.assertSnapshot(of: view)
    }

    @Test
    func throwsAside() {
        let view = MarkdownView("""
        > Throws: `InvalidInputError` when the input parameter is nil.
        """)
        SnapshotTestHelper.assertSnapshot(of: view)
    }

    @Test
    func remarkAside() {
        let view = MarkdownView("""
        > Remark: This implementation follows the observer pattern.
        """)
        SnapshotTestHelper.assertSnapshot(of: view)
    }

    @Test
    func preconditionAside() {
        let view = MarkdownView("""
        > Precondition: The array must not be empty.
        """)
        SnapshotTestHelper.assertSnapshot(of: view)
    }

    @Test
    func postconditionAside() {
        let view = MarkdownView("""
        > Postcondition: The returned value is always positive.
        """)
        SnapshotTestHelper.assertSnapshot(of: view)
    }

    @Test
    func complexityAside() {
        let view = MarkdownView("""
        > Complexity: O(n log n) where n is the number of elements.
        """)
        SnapshotTestHelper.assertSnapshot(of: view)
    }

    @Test
    func requiresAside() {
        let view = MarkdownView("""
        > Requires: iOS 17.0 or later.
        """)
        SnapshotTestHelper.assertSnapshot(of: view)
    }

    @Test
    func sinceAside() {
        let view = MarkdownView("""
        > Since: Version 2.0
        """)
        SnapshotTestHelper.assertSnapshot(of: view)
    }

    @Test
    func versionAside() {
        let view = MarkdownView("""
        > Version: 1.0.0
        """)
        SnapshotTestHelper.assertSnapshot(of: view)
    }

    @Test
    func authorAside() {
        let view = MarkdownView("""
        > Author: John Doe
        """)
        SnapshotTestHelper.assertSnapshot(of: view)
    }

    @Test
    func copyrightAside() {
        let view = MarkdownView("""
        > Copyright: 2024 Example Corp. All rights reserved.
        """)
        SnapshotTestHelper.assertSnapshot(of: view)
    }

    @Test
    func dateAside() {
        let view = MarkdownView("""
        > Date: December 2024
        """)
        SnapshotTestHelper.assertSnapshot(of: view)
    }

    @Test
    func invariantAside() {
        let view = MarkdownView("""
        > Invariant: The count is always non-negative.
        """)
        SnapshotTestHelper.assertSnapshot(of: view)
    }

    @Test
    func mutatingVariantAside() {
        let view = MarkdownView("""
        > MutatingVariant: Use `sort()` for in-place sorting.
        """)
        SnapshotTestHelper.assertSnapshot(of: view)
    }

    @Test
    func nonMutatingVariantAside() {
        let view = MarkdownView("""
        > NonMutatingVariant: Use `sorted()` to get a new sorted array.
        """)
        SnapshotTestHelper.assertSnapshot(of: view)
    }

    // MARK: - Custom Aside

    @Test
    func customAside() {
        let view = MarkdownView("""
        > MyCustomTag: This is a custom aside type.
        """)
        SnapshotTestHelper.assertSnapshot(of: view)
    }

    // MARK: - Regular Blockquote (defaults to Note)

    @Test
    func regularBlockquoteAsNote() {
        let view = MarkdownView("""
        > This is a regular blockquote without a tag.
        > It defaults to the Note aside kind.
        """)
        SnapshotTestHelper.assertSnapshot(of: view)
    }

    // MARK: - Complex Aside Content

    @Test
    func asideWithFormattedContent() {
        let view = MarkdownView("""
        > Note: This aside contains **bold** and *italic* text.
        > It also has `inline code` and a [link](https://example.com).
        """)
        SnapshotTestHelper.assertSnapshot(of: view)
    }

    @Test
    func asideWithList() {
        let view = MarkdownView("""
        > Tip: Follow these steps:
        >
        > - First, install dependencies
        > - Then, configure settings
        > - Finally, run the application
        """)
        SnapshotTestHelper.assertSnapshot(of: view)
    }

    @Test
    func asideWithCodeBlock() {
        let view = MarkdownView("""
        > Important: Use this code pattern:
        >
        > ```swift
        > let result = try await fetchData()
        > ```
        """)
        SnapshotTestHelper.assertSnapshot(of: view)
    }

    // MARK: - All Common Asides Together

    @Test
    func allCommonAsides() {
        let view = MarkdownView("""
        > Note: This is a note.

        > Tip: This is a tip.

        > Important: This is important.

        > Warning: This is a warning.

        > Experiment: This is an experiment.
        """)
        SnapshotTestHelper.assertSnapshot(of: view)
    }
}
