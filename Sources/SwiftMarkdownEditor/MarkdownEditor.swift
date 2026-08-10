import SwiftUI
import SwiftMarkdownView
import SwiftMarkdownEditorCore
import SwiftMarkdownEditorRules
import SwiftMarkdownEditorTextKit

/// A SwiftUI Markdown editor with live syntax highlighting, a formatting toolbar, and a rendered preview.
///
/// ```swift
/// @State private var text = "# Hello"
/// var body: some View {
///     MarkdownEditor(text: $text)
/// }
/// ```
///
/// The plain Markdown string in `text` is the single source of truth. Editing happens
/// in a TextKit 2 text view, and the preview reuses `MarkdownView`, so what you see
/// while editing matches what the rest of the package renders.
///
/// Coloring comes from the `MarkdownEditorTheme` in the environment. The default is
/// built from system semantic colors and follows light and dark appearance on its own,
/// so no external design system is required.
public struct MarkdownEditor: View {

    @Binding private var text: String
    private let baseFontSize: CGFloat
    private let inputRules: InputRuleProcessor
    private let livePreview: Bool
    private let toolbarItems: [MarkdownEditorToolbarItem]

    /// The controller used when the caller does not supply one.
    @StateObject private var ownedController = MarkdownEditorController()
    private let injectedController: MarkdownEditorController?

    /// The mode used when the caller does not supply a binding.
    @State private var ownedMode: MarkdownEditorMode
    private let injectedMode: Binding<MarkdownEditorMode>?

    @Environment(\.markdownEditorTheme) private var environmentTheme

    private var controller: MarkdownEditorController { injectedController ?? ownedController }
    private var mode: Binding<MarkdownEditorMode> { injectedMode ?? $ownedMode }

    /// Creates a Markdown editor bound to `text`.
    ///
    /// The editor keeps the mode to itself. To observe or drive it from outside, use
    /// ``init(text:mode:baseFontSize:livePreview:inputRules:toolbar:controller:)``.
    ///
    /// - Parameters:
    ///   - text: The Markdown source to edit.
    ///   - initialMode: The mode shown when the editor first appears.
    ///   - baseFontSize: The point size of body text, and the only place to set it. It
    ///     overrides the font size carried by the theme in the environment, whichever
    ///     way that theme was built.
    ///   - livePreview: When `true`, the editing surface conceals inline markers and
    ///     renders the source in place, Notion style. Markers reappear on the line
    ///     holding the caret while the editor is focused, and the plain `.md` text stays
    ///     the single source of truth.
    ///   - inputRules: The autoformatting rules applied while typing, such as list
    ///     continuation.
    ///   - toolbar: The formatting toolbar items. Pass an empty array to hide the
    ///     toolbar; the items' keyboard shortcuts are hidden with it.
    ///   - controller: A controller for sending commands programmatically. One is
    ///     created internally when omitted.
    public init(
        text: Binding<String>,
        initialMode: MarkdownEditorMode = .edit,
        baseFontSize: CGFloat = 16,
        livePreview: Bool = false,
        inputRules: InputRuleProcessor = .standard,
        toolbar: [MarkdownEditorToolbarItem] = .standard,
        controller: MarkdownEditorController? = nil
    ) {
        self._text = text
        self._ownedMode = State(initialValue: initialMode)
        self.injectedMode = nil
        self.baseFontSize = baseFontSize
        self.livePreview = livePreview
        self.inputRules = inputRules
        self.toolbarItems = toolbar
        self.injectedController = controller
    }

    /// Creates a Markdown editor whose mode is driven by an external binding.
    ///
    /// Use it to put the mode switcher, or the whole toolbar, in your own UI.
    ///
    /// - Parameters:
    ///   - text: The Markdown source to edit.
    ///   - mode: The display mode, kept in sync both ways with the editor's own picker.
    ///     That picker offers ``MarkdownEditorMode/split`` on macOS only, but selecting
    ///     it through this binding lays out the split on iOS too.
    ///   - baseFontSize: The point size of body text, and the only place to set it. It
    ///     overrides the font size carried by the theme in the environment, whichever
    ///     way that theme was built.
    ///   - livePreview: When `true`, the editing surface conceals inline markers and
    ///     renders the source in place. See
    ///     ``init(text:initialMode:baseFontSize:livePreview:inputRules:toolbar:controller:)``.
    ///   - inputRules: The autoformatting rules applied while typing, such as list
    ///     continuation.
    ///   - toolbar: The formatting toolbar items. Pass an empty array to hide the
    ///     toolbar; the items' keyboard shortcuts are hidden with it.
    ///   - controller: A controller for sending commands programmatically. One is
    ///     created internally when omitted.
    public init(
        text: Binding<String>,
        mode: Binding<MarkdownEditorMode>,
        baseFontSize: CGFloat = 16,
        livePreview: Bool = false,
        inputRules: InputRuleProcessor = .standard,
        toolbar: [MarkdownEditorToolbarItem] = .standard,
        controller: MarkdownEditorController? = nil
    ) {
        self._text = text
        self._ownedMode = State(initialValue: mode.wrappedValue)
        self.injectedMode = mode
        self.baseFontSize = baseFontSize
        self.livePreview = livePreview
        self.inputRules = inputRules
        self.toolbarItems = toolbar
        self.injectedController = controller
    }

    private var theme: MarkdownEditorTheme {
        var resolved = environmentTheme
        resolved.baseFontSize = baseFontSize
        return resolved
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
        .background(Color(theme.backgroundColor))
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 0) {
            // Mode switcher row. The control fills the width so its segments are
            // equal (each segment is maxWidth: .infinity internally); a content-
            // hugging control would size segments to their labels and look uneven.
            Picker("", selection: mode) {
                ForEach(availableModes, id: \.self) { candidate in
                    Text(candidate.displayName).tag(candidate)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .frame(maxWidth: 420)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 8)
            .padding(.top, 6)

            // Formatting toolbar row. In preview-only mode the source text view is
            // not mounted, so formatting commands would have nothing to act on.
            if mode.wrappedValue != .preview && !toolbarItems.isEmpty {
                MarkdownFormattingToolbar(controller: controller, items: toolbarItems)
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        switch mode.wrappedValue {
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
