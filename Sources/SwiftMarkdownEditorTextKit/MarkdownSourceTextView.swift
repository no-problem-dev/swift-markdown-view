import SwiftUI
import SwiftMarkdownEditorCore
import SwiftMarkdownEditorRules

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// A SwiftUI wrapper around a TextKit 2 `UITextView`/`NSTextView` that edits
/// Markdown source with live syntax highlighting.
///
/// Design notes (per the editor strategy):
/// - Built on TextKit 2 (`usingTextLayoutManager: true`); the code never touches
///   `.layoutManager`, which would silently drop the view back to TextKit 1.
/// - Highlighting is attribute-only, re-applied on change, preserving selection.
/// - Markdown smart quotes/dashes are disabled — they corrupt `*`/`-`/`"` syntax.
/// - Autoformatting (list continuation, smart wrapping) is routed through the
///   pure ``InputRuleProcessor`` from the rules layer.
public struct MarkdownSourceTextView {

    @Binding public var text: String
    public var theme: MarkdownEditorTheme
    public var inputRules: InputRuleProcessor
    public var isEditable: Bool
    /// When true, inline markers are concealed and the source renders inline
    /// (Notion-style live preview); the line the caret touches reveals its raw
    /// markers. When false, markers stay visible with source highlighting.
    public var livePreview: Bool
    /// Receives the platform text view once created (lets a controller drive
    /// formatting actions from a SwiftUI toolbar).
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

    /// A hash of the inputs that affect styling. `updateUIView`/`updateNSView`
    /// re-styles only when this changes, never on every layout pass.
    func styleSignature() -> Int {
        var hasher = Hasher()
        hasher.combine(livePreview)
        hasher.combine(theme.baseFontSize)
        hasher.combine(isEditable)
        return hasher.finalize()
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
        /// Guards against re-entrant binding updates while we set text ourselves.
        var isApplyingProgrammaticChange = false
        /// The style inputs last applied, so `updateUIView`/`updateNSView` stays
        /// idempotent — re-styling only when theme/mode actually changed, never
        /// on every layout pass (which would loop during snapshot measuring).
        var appliedStyleSignature: Int?

        init(text: Binding<String>, theme: MarkdownEditorTheme, inputRules: InputRuleProcessor, livePreview: Bool) {
            self.text = text
            self.theme = theme
            self.inputRules = inputRules
            self.livePreview = livePreview
        }

        /// Applies styling to `storage` in place. In live-preview mode this
        /// conceals/reveals markers based on `selection`/`focused`; otherwise it
        /// applies plain source highlighting.
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

        /// Re-applies styling, preserving `selection`.
        func rehighlight(_ storage: NSTextStorage, selection: NSRange, focused: Bool, restore: (NSRange) -> Void) {
            applyStyling(to: storage, selection: selection, focused: focused)
            restore(selection)
        }

        /// Resolves an input rule for the pending edit, if any.
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
        // 下方向スクロールのドラッグでキーボードを閉じられるようにする。
        textView.keyboardDismissMode = .interactive

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
        let clamped = NSRange(location: min(selection.location, value.utf16.count), length: 0)
        textView.selectedRange = clamped
        coordinator.applyStyling(to: textView.textStorage, selection: clamped, focused: textView.isFirstResponder)
        textView.typingAttributes = MarkdownSyntaxHighlighter.baseAttributes(theme: theme)
        coordinator.appliedStyleSignature = styleSignature()
        coordinator.isApplyingProgrammaticChange = false
    }
}

extension MarkdownSourceTextView.Coordinator: UITextViewDelegate {

    public func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText replacement: String) -> Bool {
        guard let transform = ruleTransform(currentText: textView.text, replacing: range, with: replacement) else {
            return true
        }
        apply(transform, to: textView)
        return false
    }

    public func textViewDidChange(_ textView: UITextView) {
        guard !isApplyingProgrammaticChange else { return }
        text.wrappedValue = textView.text
        rehighlight(textView.textStorage, selection: textView.selectedRange, focused: textView.isFirstResponder) { textView.selectedRange = $0 }
        textView.typingAttributes = MarkdownSyntaxHighlighter.baseAttributes(theme: theme)
    }

    public func textViewDidChangeSelection(_ textView: UITextView) {
        // Live preview reveals the raw markers on the caret's line as the
        // selection moves; re-style without disturbing text or selection.
        guard livePreview, !isApplyingProgrammaticChange else { return }
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
        // Phase 1 note: `scrollableTextView()` vends a TextKit 1 NSTextView.
        // Attribute-only highlighting works identically on TextKit 1, so source
        // editing is correct here. Phase 2 (inline live preview with layout
        // fragments) will replace this with an explicit TextKit 2 NSTextView.
        let scrollView = NSTextView.scrollableTextView()
        let textView = scrollView.documentView as! NSTextView

        textView.delegate = context.coordinator
        textView.isEditable = isEditable
        textView.isRichText = false
        textView.allowsUndo = true
        textView.backgroundColor = theme.backgroundColor
        textView.insertionPointColor = theme.tintColor
        textView.textContainerInset = NSSize(width: 8, height: 12)

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
        coordinator.isApplyingProgrammaticChange = true
        storage.setAttributedString(NSAttributedString(string: value, attributes: MarkdownSyntaxHighlighter.baseAttributes(theme: theme)))
        coordinator.applyStyling(to: storage, selection: textView.selectedRange(), focused: MarkdownSourceTextView.isFocused(textView))
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
        guard let replacement,
              let transform = ruleTransform(currentText: textView.string, replacing: affectedCharRange, with: replacement) else {
            return true
        }
        apply(transform, to: textView)
        return false
    }

    public func textDidChange(_ notification: Notification) {
        guard !isApplyingProgrammaticChange, let textView = notification.object as? NSTextView, let storage = textView.textStorage else { return }
        text.wrappedValue = textView.string
        rehighlight(storage, selection: textView.selectedRange(), focused: MarkdownSourceTextView.isFocused(textView)) { textView.setSelectedRange($0) }
        textView.typingAttributes = MarkdownSyntaxHighlighter.baseAttributes(theme: theme)
    }

    public func textViewDidChangeSelection(_ notification: Notification) {
        guard livePreview, !isApplyingProgrammaticChange,
              let textView = notification.object as? NSTextView, let storage = textView.textStorage else { return }
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
