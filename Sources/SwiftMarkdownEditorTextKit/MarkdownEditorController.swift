import SwiftUI
import SwiftMarkdownEditorCore

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// Bridges a SwiftUI toolbar to the platform text view that is currently editing.
///
/// The editor creates one of these, hands it to ``MarkdownSourceTextView`` through its
/// `onMakeTextView` callback, and wires toolbar buttons to its commands. Every command computes a
/// pure `EditTransform` with `MarkdownFormatting` and applies it through the native editing API,
/// so the edit lands on the system undo stack and the user can undo it like any other typing.
///
/// Reach for ``state`` and ``apply(_:)`` to drive that same pipeline from a command of your own.
@MainActor
public final class MarkdownEditorController: ObservableObject {

    weak var textView: PlatformTextView?

    /// Holds the observer tokens indirectly, because `deinit` is not MainActor-isolated and so
    /// cannot reach isolated stored properties.
    private let undoObservers = ObserverBox()

    public init() {}

    /// Registers the platform text view this controller drives.
    ///
    /// The editor calls this as the text view is created. Binding a new text view replaces the
    /// previous one and restarts undo observation.
    public func bind(_ textView: PlatformTextView) {
        self.textView = textView
        observeUndoStack()
    }

    /// Forwards changes on the undo stack to `objectWillChange`.
    ///
    /// ``canUndo`` and ``canRedo`` are computed straight from the `UndoManager`, so without this
    /// SwiftUI never re-evaluates them and a caller's own undo button stays permanently disabled —
    /// the symptom seen on device.
    private func observeUndoStack() {
        undoObservers.removeAll()
        let center = NotificationCenter.default
        let names: [Notification.Name] = [
            .NSUndoManagerDidUndoChange,
            .NSUndoManagerDidRedoChange,
            .NSUndoManagerDidCloseUndoGroup,
            .NSUndoManagerDidOpenUndoGroup,
            .NSUndoManagerWillCloseUndoGroup
        ]
        // Observe every object rather than this text view's undo manager. `NSTextView.undoManager`
        // resolves through the responder chain to the window, so it is still nil at `bind(_:)` time,
        // and pinning the observation to it there means no notification ever arrives. Picking up
        // other undo managers too costs only a few redundant SwiftUI invalidations.
        undoObservers.tokens = names.map { name in
            center.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
                MainActor.assumeIsolated { self?.objectWillChange.send() }
            }
        }
    }

    // MARK: - Toolbar commands

    // All of these toggle: applying one to a selection or line that already carries it removes it.
    public func toggleBold() { toggleWrap("**") }
    public func toggleItalic() { toggleWrap("*") }
    public func toggleInlineCode() { toggleWrap("`") }
    public func toggleStrikethrough() { toggleWrap("~~") }

    public func toggleHeading() { toggleLinePrefix("# ") }
    public func toggleQuote() { toggleLinePrefix("> ") }
    public func toggleBulletList() { toggleLinePrefix("- ") }

    /// Wraps the selection in a delimiter, or unwraps it when it is already wrapped.
    public func toggleWrap(_ delimiter: String) {
        guard let (text, selection) = readState() else { return }
        applyTransform(MarkdownFormatting.wrap(text: text, selection: selection, delimiter: delimiter))
    }

    /// Adds a prefix to every selected line, or removes it when every line already has it.
    public func toggleLinePrefix(_ prefix: String) {
        guard let (text, selection) = readState() else { return }
        applyTransform(MarkdownFormatting.toggleLinePrefix(text: text, selection: selection, prefix: prefix))
    }

    public func insertLink() {
        guard let (text, selection) = readState() else { return }
        applyTransform(MarkdownFormatting.insertLink(text: text, selection: selection))
    }

    // MARK: - Undo / redo

    public func undo() { undoManager?.undo() }
    public func redo() { undoManager?.redo() }
    public var canUndo: Bool { undoManager?.canUndo ?? false }
    public var canRedo: Bool { undoManager?.canRedo ?? false }

    /// Makes the text view first responder, so the keyboard appears and typing has a target.
    ///
    /// - Returns: `false` when no text view is bound or the text view refused first responder
    ///   status — on macOS that includes the case where it is not yet in a window.
    @discardableResult
    public func focus() -> Bool {
        #if canImport(UIKit)
        return textView?.becomeFirstResponder() ?? false
        #elseif canImport(AppKit)
        guard let textView else { return false }
        return textView.window?.makeFirstResponder(textView) ?? false
        #endif
    }

    // MARK: - Platform bridging

    private var undoManager: UndoManager? {
        #if canImport(UIKit)
        return textView?.undoManager
        #elseif canImport(AppKit)
        return textView?.undoManager
        #endif
    }

    // MARK: - Custom commands

    /// The current document text and selection, or `nil` when no text view is bound.
    ///
    /// Pair it with the pure functions of `MarkdownFormatting` to build a command of your own:
    ///
    /// ```swift
    /// guard let state = controller.state else { return }
    /// controller.apply(MarkdownFormatting.wrap(
    ///     text: state.text, selection: state.selection, delimiter: "=="
    /// ))
    /// ```
    public var state: EditorState? {
        guard let (text, selection) = readState() else { return nil }
        return EditorState(text: text, selection: selection)
    }

    /// Applies a transform to the bound text view.
    ///
    /// The built-in commands such as ``toggleBold()`` go through here too. The edit is made with the
    /// native editing API, so the system `UndoManager` records it and the user can undo it. Does
    /// nothing when no text view is bound.
    public func apply(_ transform: EditTransform) {
        applyTransform(transform)
    }

    private func readState() -> (text: String, selection: Selection)? {
        guard let textView else { return nil }
        #if canImport(UIKit)
        return (textView.text, Selection(range: TextSpan(textView.selectedRange)))
        #elseif canImport(AppKit)
        return (textView.string, Selection(range: TextSpan(textView.selectedRange())))
        #endif
    }

    private func applyTransform(_ transform: EditTransform) {
        guard let textView else { return }
        let range = transform.change.range.nsRange

        #if canImport(UIKit)
        if let start = textView.position(from: textView.beginningOfDocument, offset: range.location),
           let end = textView.position(from: start, offset: range.length),
           let textRange = textView.textRange(from: start, to: end) {
            textView.replace(textRange, withText: transform.change.replacement)
        }
        textView.selectedRange = transform.selection.range.nsRange
        #elseif canImport(AppKit)
        if textView.shouldChangeText(in: range, replacementString: transform.change.replacement) {
            textView.textStorage?.replaceCharacters(in: range, with: transform.change.replacement)
            textView.didChangeText()
        }
        textView.setSelectedRange(transform.selection.range.nsRange)
        #endif
    }
}


/// Holds notification observer tokens and removes them when it is released.
///
/// `MarkdownEditorController` is `@MainActor`, so its `deinit` cannot touch isolated properties.
/// Moving the tokens into a non-isolated class puts the removal somewhere `deinit` can reach.
private final class ObserverBox: @unchecked Sendable {

    var tokens: [any NSObjectProtocol] = []

    func removeAll() {
        let center = NotificationCenter.default
        for token in tokens { center.removeObserver(token) }
        tokens.removeAll()
    }

    deinit { removeAll() }
}
