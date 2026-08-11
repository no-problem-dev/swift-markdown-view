#if canImport(UIKit)
import Testing
import SwiftUI
import VisualTesting
@testable import SwiftMarkdownEditor

/// Snapshot tests for the public ``MarkdownEditor`` view.
///
/// We snapshot the editor in its various modes with a fixed sample document, so
/// changes to highlighting, the toolbar, or the layout are caught visually
/// without driving the simulator interactively.
@SnapshotSuite("MarkdownEditor")
@MainActor
struct MarkdownEditorSnapshotTests {

    init() { setupVisualTesting() }

    private static let sample = """
    # Markdown Editor

    Type **bold**, *italic*, ~~strike~~ and `code`.

    - first item
    - second item
    - [ ] a task

    > A blockquote.

    ```swift
    let answer = 42
    ```

    See [Apple](https://apple.com) for more.
    """

    // MARK: - Edit mode (toolbar + highlighted source)

    @ComponentSnapshot(width: 390, height: 560)
    func editMode() -> some View {
        MarkdownEditor(text: .constant(Self.sample), initialMode: .edit)
            .frame(width: 390, height: 560)
    }

    // MARK: - Preview mode (rendered)

    @ComponentSnapshot(width: 390, height: 560)
    func previewMode() -> some View {
        MarkdownEditor(text: .constant(Self.sample), initialMode: .preview)
            .frame(width: 390, height: 560)
    }

    // MARK: - Highlighting detail on a short document

    @ComponentSnapshot(width: 390, height: 300)
    func highlightingDetail() -> some View {
        MarkdownEditor(text: .constant("""
        # Heading
        Some **bold** and *italic* and `inline code`.
        - bullet
        1. numbered
        > quote
        """), initialMode: .edit)
            .frame(width: 390, height: 300)
    }

    // MARK: - The theme's own base font size

    /// A theme two thirds larger than the default, so honouring it is unmistakable.
    private static var largeTheme: MarkdownEditorTheme {
        var theme = MarkdownEditorTheme.light
        theme.baseFontSize = 26
        return theme
    }

    /// The editor used to overwrite the theme's `baseFontSize` with an initializer parameter of
    /// its own, so this document rendered at 16 no matter what the theme carried. It now takes
    /// the theme whole, and the text here is visibly larger than in `highlightingDetail`.
    @ComponentSnapshot(width: 390, height: 300)
    func themedFontSize() -> some View {
        MarkdownEditor(text: .constant("""
        # Heading
        Some **bold** and *italic* and `inline code`.
        - bullet
        """), initialMode: .edit)
            .markdownEditorTheme(Self.largeTheme)
            .frame(width: 390, height: 300)
    }

    // Live-preview rendering is verified without the simulator in
    // LivePreviewRendererTests (attribute-level assertions on NSTextStorage).

    @Test func snapshots() {
        for snapshotCase in Self.__snapshotCases { snapshotCase.run() }
    }
}
#endif
