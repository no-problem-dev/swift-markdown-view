import SwiftUI
import SwiftMarkdownEditorCore
import SwiftMarkdownEditorRules

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// A SwiftUI view that edits Markdown source with live syntax highlighting.
///
/// It wraps `UITextView` on iOS and `NSTextView` on macOS. Things worth knowing about the bridge:
///
/// - The iOS text view runs on TextKit 2 (`usingTextLayoutManager: true`). Do not reach for
///   `.layoutManager`: touching it silently drops the view back to TextKit 1.
/// - The macOS text view comes from `NSTextView.scrollableTextView()`, which vends a TextKit 1 view.
///   Highlighting is attribute-only and behaves identically there.
/// - Highlighting changes attributes only, is re-applied on every edit, and preserves the selection.
/// - Smart quotes and smart dashes are turned off: they corrupt `*`, `-`, and `"` syntax.
/// - Autoformatting such as list continuation is routed through the pure `InputRuleProcessor` in
///   the rules layer.
public struct MarkdownSourceTextView {

    @Binding public var text: String
    public var theme: MarkdownEditorTheme
    public var inputRules: InputRuleProcessor
    public var isEditable: Bool
    /// Renders the source in place with the inline markers hidden.
    ///
    /// The markers reappear on the lines the selection touches, and stay hidden everywhere while the
    /// editor is not focused. When `false`, markers stay visible with plain source highlighting.
    public var livePreview: Bool

    /// Called once with the text view, as it is created.
    ///
    /// This is how a ``MarkdownEditorController`` gets hold of the view, so that a SwiftUI toolbar
    /// can drive formatting actions on it.
    public var onMakeTextView: ((PlatformTextView) -> Void)?

    public init(
        text: Binding<String>,
        theme: MarkdownEditorTheme = .light,
        inputRules: InputRuleProcessor = .standard,
        isEditable: Bool = true,
        livePreview: Bool = false,
        onMakeTextView: ((PlatformTextView) -> Void)? = nil
    ) {
        self._text = text
        self.theme = theme
        self.inputRules = inputRules
        self.isEditable = isEditable
        self.livePreview = livePreview
        self.onMakeTextView = onMakeTextView
    }

    @MainActor
    public func makeCoordinator() -> Coordinator {
        Coordinator(text: $text, theme: theme, inputRules: inputRules, livePreview: livePreview)
    }

    /// A hash of the inputs that affect styling.
    ///
    /// The update methods re-style only when this changes, rather than on every layout pass.
    func styleSignature() -> Int {
        var hasher = Hasher()
        hasher.combine(livePreview)
        hasher.combine(theme.baseFontSize)
        hasher.combine(isEditable)
        return hasher.finalize()
    }
}

// MARK: - Shared helpers

public extension MarkdownSourceTextView {

    /// Clamps a selection so that it fits inside a new text length.
    ///
    /// Used when the parent replaces the text. There is no diff to map positions through, so this
    /// cannot be exact, but a selection that still fits is worth keeping: collapsing the length to
    /// zero unconditionally would wipe the user's selection on every normalization, reformat,
    /// external undo, and reload.
    static func clampSelection(_ selection: NSRange, toLength length: Int) -> NSRange {
        let location = Swift.max(0, Swift.min(selection.location, length))
        let available = length - location
        return NSRange(location: location, length: Swift.max(0, Swift.min(selection.length, available)))
    }
}

// MARK: - Coordinator (shared logic)

public extension MarkdownSourceTextView {

    @MainActor
    final class Coordinator: NSObject {
        var text: Binding<String>
        var theme: MarkdownEditorTheme
        var inputRules: InputRuleProcessor
        var livePreview: Bool
        /// Guards against re-entrant binding updates while the view is setting the text itself.
        var isApplyingProgrammaticChange = false

        /// The style inputs behind the attributes currently applied.
        ///
        /// It keeps the update methods idempotent: they re-style only when the theme or the mode
        /// really changed, not on every layout pass — which would loop during snapshot measurement.
        var appliedStyleSignature: Int?

        init(text: Binding<String>, theme: MarkdownEditorTheme, inputRules: InputRuleProcessor, livePreview: Bool) {
            self.text = text
            self.theme = theme
            self.inputRules = inputRules
            self.livePreview = livePreview
        }

        /// Applies styling to the storage in place.
        ///
        /// In live preview mode the markers are hidden or revealed according to the selection and
        /// the focus state; otherwise plain source highlighting is applied.
        func applyStyling(to storage: NSTextStorage, selection: NSRange, focused: Bool) {
            storage.beginEditing()
            if livePreview {
                LivePreviewRenderer.apply(
                    text: storage.string,
                    selection: Selection(range: TextSpan(selection)),
                    focused: focused,
                    to: storage,
                    theme: theme
                )
            } else {
                MarkdownSyntaxHighlighter.highlight(storage, theme: theme)
            }
            storage.endEditing()
        }

        /// Re-applies the styling, then hands the selection back to the caller to restore.
        func rehighlight(_ storage: NSTextStorage, selection: NSRange, focused: Bool, restore: (NSRange) -> Void) {
            applyStyling(to: storage, selection: selection, focused: focused)
            restore(selection)
        }

        /// The input rule transform for a pending edit, or `nil` when no rule matches it.
        func ruleTransform(currentText: String, replacing range: NSRange, with replacement: String) -> RuleTransform? {
            let state = EditorState(text: currentText, selection: Selection(range: TextSpan(range)))
            return inputRules.transform(state: state, inserting: replacement, replacing: TextSpan(range))
        }
    }
}

// MARK: - iOS

#if canImport(UIKit)
extension MarkdownSourceTextView: UIViewRepresentable {

    public func makeUIView(context: Context) -> UITextView {
        let textView = UITextView(usingTextLayoutManager: true)
        assert(textView.textLayoutManager != nil, "Expected TextKit 2 to be active")

        textView.delegate = context.coordinator
        textView.isEditable = isEditable
        textView.isScrollEnabled = true
        textView.backgroundColor = theme.backgroundColor
        textView.tintColor = theme.tintColor
        textView.alwaysBounceVertical = true
        textView.textContainerInset = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        // Let a downward scroll drag dismiss the keyboard.
        textView.keyboardDismissMode = .interactive
        // Find and replace. The iOS 17 minimum lets us take the standard find interaction as-is.
        textView.isFindInteractionEnabled = true

        // Markdown-safe input: smart substitutions corrupt syntax.
        textView.smartQuotesType = .no
        textView.smartDashesType = .no
        textView.smartInsertDeleteType = .no
        textView.autocapitalizationType = .sentences

        textView.typingAttributes = MarkdownSyntaxHighlighter.baseAttributes(theme: theme)
        setText(text, on: textView, coordinator: context.coordinator)

        onMakeTextView?(textView)
        return textView
    }

    public func updateUIView(_ textView: UITextView, context: Context) {
        context.coordinator.text = $text
        context.coordinator.theme = theme
        context.coordinator.inputRules = inputRules
        context.coordinator.livePreview = livePreview
        textView.isEditable = isEditable

        let signature = styleSignature()
        if textView.text != text {
            setText(text, on: textView, coordinator: context.coordinator)
        } else if context.coordinator.appliedStyleSignature != signature {
            // Reflect theme / mode changes once, without touching text, binding,
            // or selection — never on every layout pass (which would loop).
            context.coordinator.isApplyingProgrammaticChange = true
            context.coordinator.applyStyling(to: textView.textStorage, selection: textView.selectedRange, focused: textView.isFirstResponder)
            context.coordinator.isApplyingProgrammaticChange = false
        }
        context.coordinator.appliedStyleSignature = signature
    }

    @MainActor
    private func setText(_ value: String, on textView: UITextView, coordinator: Coordinator) {
        let selection = textView.selectedRange
        coordinator.isApplyingProgrammaticChange = true
        textView.textStorage.setAttributedString(
            NSAttributedString(string: value, attributes: MarkdownSyntaxHighlighter.baseAttributes(theme: theme))
        )
        // Keep the selection, length included, as far as it still fits the new text.
        let clamped = Self.clampSelection(selection, toLength: value.utf16.count)
        textView.selectedRange = clamped
        coordinator.applyStyling(to: textView.textStorage, selection: clamped, focused: textView.isFirstResponder)
        textView.typingAttributes = MarkdownSyntaxHighlighter.baseAttributes(theme: theme)
        coordinator.appliedStyleSignature = styleSignature()
        coordinator.isApplyingProgrammaticChange = false
    }
}

extension MarkdownSourceTextView.Coordinator: UITextViewDelegate {

    public func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText replacement: String) -> Bool {
        // Do not run input rules while there is marked text. Returning false here tears down the
        // composition session from the outside and the candidate list disappears.
        guard textView.markedTextRange == nil else { return true }
        guard let transform = ruleTransform(currentText: textView.text, replacing: range, with: replacement) else {
            return true
        }
        apply(transform, to: textView)
        return false
    }

    public func textViewDidChange(_ textView: UITextView) {
        guard !isApplyingProgrammaticChange else { return }
        // Marked text carries its underline and clause highlighting as attributes, which a full
        // re-attribute pass would wipe out. It also keeps unconfirmed input out of the parent state.
        guard textView.markedTextRange == nil else { return }
        text.wrappedValue = textView.text
        rehighlight(textView.textStorage, selection: textView.selectedRange, focused: textView.isFirstResponder) { textView.selectedRange = $0 }
        textView.typingAttributes = MarkdownSyntaxHighlighter.baseAttributes(theme: theme)
    }

    public func textViewDidChangeSelection(_ textView: UITextView) {
        // Live preview reveals the raw markers on the caret's line as the
        // selection moves; re-style without disturbing text or selection.
        guard livePreview, !isApplyingProgrammaticChange, textView.markedTextRange == nil else { return }
        isApplyingProgrammaticChange = true
        applyStyling(to: textView.textStorage, selection: textView.selectedRange, focused: textView.isFirstResponder)
        isApplyingProgrammaticChange = false
    }

    private func apply(_ transform: RuleTransform, to textView: UITextView) {
        let range = transform.change.range.nsRange
        if let start = textView.position(from: textView.beginningOfDocument, offset: range.location),
           let end = textView.position(from: start, offset: range.length),
           let textRange = textView.textRange(from: start, to: end) {
            textView.replace(textRange, withText: transform.change.replacement)
        }
        textView.selectedRange = transform.selection.range.nsRange
        text.wrappedValue = textView.text
        rehighlight(textView.textStorage, selection: textView.selectedRange, focused: textView.isFirstResponder) { textView.selectedRange = $0 }
        textView.typingAttributes = MarkdownSyntaxHighlighter.baseAttributes(theme: theme)
    }
}
#endif

// MARK: - macOS

#if canImport(AppKit) && !targetEnvironment(macCatalyst)
extension MarkdownSourceTextView: NSViewRepresentable {

    public func makeNSView(context: Context) -> NSScrollView {
        // `scrollableTextView()` vends a TextKit 1 NSTextView. Highlighting is attribute-only, so
        // source editing behaves identically here; only inline live preview built on layout
        // fragments would need an explicit TextKit 2 NSTextView instead.
        let scrollView = NSTextView.scrollableTextView()
        let textView = scrollView.documentView as! NSTextView

        textView.delegate = context.coordinator
        textView.isEditable = isEditable
        textView.isRichText = false
        textView.allowsUndo = true
        textView.backgroundColor = theme.backgroundColor
        textView.insertionPointColor = theme.tintColor
        textView.textContainerInset = NSSize(width: 8, height: 12)

        // Find and replace, through the standard find bar.
        //
        // ⌘F does not reach the text view from here, though — it arrives from the host app's Edit
        // menu. A SwiftUI app's default menu carries no Find, so ⌘F does nothing at all unless the
        // app declares `.commands { TextEditingCommands() }`. The editor chapter of the README has
        // the steps.
        textView.usesFindBar = true
        textView.isIncrementalSearchingEnabled = true

        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false

        textView.typingAttributes = MarkdownSyntaxHighlighter.baseAttributes(theme: theme)
        setText(text, on: textView, coordinator: context.coordinator)

        onMakeTextView?(textView)
        return scrollView
    }

    public func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? NSTextView else { return }
        context.coordinator.text = $text
        context.coordinator.theme = theme
        context.coordinator.inputRules = inputRules
        context.coordinator.livePreview = livePreview
        textView.isEditable = isEditable

        let signature = styleSignature()
        if textView.string != text {
            setText(text, on: textView, coordinator: context.coordinator)
        } else if context.coordinator.appliedStyleSignature != signature, let storage = textView.textStorage {
            context.coordinator.isApplyingProgrammaticChange = true
            context.coordinator.applyStyling(to: storage, selection: textView.selectedRange(), focused: MarkdownSourceTextView.isFocused(textView))
            context.coordinator.isApplyingProgrammaticChange = false
        }
        context.coordinator.appliedStyleSignature = signature
    }

    @MainActor
    private func setText(_ value: String, on textView: NSTextView, coordinator: Coordinator) {
        guard let storage = textView.textStorage else { return }
        let selection = textView.selectedRange()
        coordinator.isApplyingProgrammaticChange = true
        storage.setAttributedString(NSAttributedString(string: value, attributes: MarkdownSyntaxHighlighter.baseAttributes(theme: theme)))
        // As on iOS: keep the selection as far as it still fits the new text.
        let clamped = Self.clampSelection(selection, toLength: (value as NSString).length)
        textView.setSelectedRange(clamped)
        coordinator.applyStyling(to: storage, selection: clamped, focused: MarkdownSourceTextView.isFocused(textView))
        textView.typingAttributes = MarkdownSyntaxHighlighter.baseAttributes(theme: theme)
        coordinator.appliedStyleSignature = styleSignature()
        coordinator.isApplyingProgrammaticChange = false
    }

    @MainActor
    static func isFocused(_ textView: NSTextView) -> Bool {
        textView.window?.firstResponder === textView
    }
}

extension MarkdownSourceTextView.Coordinator: NSTextViewDelegate {

    public func textView(_ textView: NSTextView, shouldChangeTextIn affectedCharRange: NSRange, replacementString replacement: String?) -> Bool {
        guard !textView.hasMarkedText() else { return true }
        guard let replacement,
              let transform = ruleTransform(currentText: textView.string, replacing: affectedCharRange, with: replacement) else {
            return true
        }
        apply(transform, to: textView)
        return false
    }

    public func textDidChange(_ notification: Notification) {
        guard !isApplyingProgrammaticChange, let textView = notification.object as? NSTextView, let storage = textView.textStorage else { return }
        guard !textView.hasMarkedText() else { return }
        text.wrappedValue = textView.string
        rehighlight(storage, selection: textView.selectedRange(), focused: MarkdownSourceTextView.isFocused(textView)) { textView.setSelectedRange($0) }
        textView.typingAttributes = MarkdownSyntaxHighlighter.baseAttributes(theme: theme)
    }

    public func textViewDidChangeSelection(_ notification: Notification) {
        guard livePreview, !isApplyingProgrammaticChange,
              let textView = notification.object as? NSTextView, let storage = textView.textStorage,
              !textView.hasMarkedText() else { return }
        isApplyingProgrammaticChange = true
        applyStyling(to: storage, selection: textView.selectedRange(), focused: MarkdownSourceTextView.isFocused(textView))
        isApplyingProgrammaticChange = false
    }

    private func apply(_ transform: RuleTransform, to textView: NSTextView) {
        guard let storage = textView.textStorage else { return }
        let range = transform.change.range.nsRange
        if textView.shouldChangeText(in: range, replacementString: transform.change.replacement) {
            storage.replaceCharacters(in: range, with: transform.change.replacement)
            textView.didChangeText()
        }
        textView.setSelectedRange(transform.selection.range.nsRange)
        text.wrappedValue = textView.string
        rehighlight(storage, selection: textView.selectedRange(), focused: MarkdownSourceTextView.isFocused(textView)) { textView.setSelectedRange($0) }
        textView.typingAttributes = MarkdownSyntaxHighlighter.baseAttributes(theme: theme)
    }
}
#endif
