import SwiftUI
import DesignSystem
import SwiftMarkdownView
import SwiftMarkdownEditorCore
import SwiftMarkdownEditorRules
import SwiftMarkdownEditorTextKit

/// A SwiftUI Markdown editor with live syntax highlighting, a formatting
/// toolbar, and an optional rendered preview.
///
/// ```swift
/// @State private var text = "# Hello"
/// var body: some View {
///     MarkdownEditor(text: $text)
/// }
/// ```
///
/// The plain Markdown string in `text` is always the single source of truth.
/// Editing happens on a TextKit 2 text view; the preview reuses ``MarkdownView``
/// so the rendered output matches the rest of the package exactly. Colors and
/// spacing come from the `swift-design-system` theme in the environment.
public struct MarkdownEditor: View {

    @Binding private var text: String
    private let baseFontSize: CGFloat
    private let inputRules: InputRuleProcessor
    private let livePreview: Bool

    @StateObject private var controller = MarkdownEditorController()
    @State private var mode: MarkdownEditorMode
    @Environment(\.colorPalette) private var palette

    /// Creates a Markdown editor bound to `text`.
    ///
    /// - Parameters:
    ///   - text: The Markdown source to edit.
    ///   - initialMode: The starting presentation mode.
    ///   - baseFontSize: The editor's base font size.
    ///   - livePreview: When true, the edit surface conceals inline markers and
    ///     renders the source in place (Notion-style); the caret's line reveals
    ///     its raw markers. The plain `.md` text stays the source of truth.
    ///   - inputRules: The autoformatting rules (defaults to the standard set).
    public init(
        text: Binding<String>,
        initialMode: MarkdownEditorMode = .edit,
        baseFontSize: CGFloat = 16,
        livePreview: Bool = false,
        inputRules: InputRuleProcessor = .standard
    ) {
        self._text = text
        self._mode = State(initialValue: initialMode)
        self.baseFontSize = baseFontSize
        self.livePreview = livePreview
        self.inputRules = inputRules
    }

    private var theme: MarkdownEditorTheme {
        .fromDesignSystem(palette: palette, baseFontSize: baseFontSize)
    }

    private var availableModes: [MarkdownEditorMode] {
        #if os(macOS)
        [.edit, .split, .preview]
        #else
        [.edit, .preview]
        #endif
    }

    public var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            content
        }
        .background(palette.surface)
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 0) {
            // Mode switcher row. The control fills the width so its segments are
            // equal (each segment is maxWidth: .infinity internally); a content-
            // hugging control would size segments to their labels and look uneven.
            SegmentedControl(selection: $mode, options: availableModes) { mode in
                Text(mode.displayName)
            }
            .frame(maxWidth: 420)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 8)
            .padding(.top, 6)

            // Formatting toolbar row (hidden in pure preview).
            if mode != .preview {
                MarkdownFormattingToolbar(controller: controller)
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        switch mode {
        case .edit:
            editor
        case .preview:
            preview
        case .split:
            HStack(spacing: 0) {
                editor
                Divider()
                preview
            }
        }
    }

    private var editor: some View {
        MarkdownSourceTextView(
            text: $text,
            theme: theme,
            inputRules: inputRules,
            livePreview: livePreview,
            onMakeTextView: { controller.bind($0) }
        )
    }

    private var preview: some View {
        ScrollView {
            MarkdownView(text)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
        }
    }
}

#Preview {
    struct PreviewHost: View {
        @State private var text = """
        # Markdown Editor

        Type **bold**, *italic*, and `code`.

        - one
        - two

        > A quote.
        """
        var body: some View {
            MarkdownEditor(text: $text)
        }
    }
    return PreviewHost()
}
