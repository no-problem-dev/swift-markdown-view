import SwiftUI
import SwiftMarkdownEditorCore

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// SwiftUI ツールバーをアクティブなプラットフォームテキストビューに橋渡しする。
///
/// SwiftUI エディタがこのオブジェクトを作成し、`onMakeTextView` 経由で ``MarkdownSourceTextView`` に渡し、
/// ツールバーボタンをコマンドに接続する。各コマンドは純粋な ``EditTransform``（``MarkdownFormatting``）を
/// 計算し、ネイティブ編集 API を通じてテキストビューに適用するため、システムの undo スタックが使われる。
@MainActor
public final class MarkdownEditorController: ObservableObject {

    weak var textView: PlatformTextView?

    public init() {}

    /// このコントローラが操作するプラットフォームテキストビューを登録する。
    /// テキストビューの作成時にエディタビューから呼ばれる。
    public func bind(_ textView: PlatformTextView) {
        self.textView = textView
    }

    // MARK: - Toolbar commands

    // 全て toggle。既に適用済みの選択範囲・行に対しては解除する。
    // 以前は toggleHeading / toggleQuote だけが toggle を名乗り、同じ挙動の
    // bold / italic / code / strikethrough / bulletList が動詞形だった。
    public func toggleBold() { toggleWrap("**") }
    public func toggleItalic() { toggleWrap("*") }
    public func toggleInlineCode() { toggleWrap("`") }
    public func toggleStrikethrough() { toggleWrap("~~") }

    public func toggleHeading() { toggleLinePrefix("# ") }
    public func toggleQuote() { toggleLinePrefix("> ") }
    public func toggleBulletList() { toggleLinePrefix("- ") }

    /// 選択範囲を区切り文字で囲む。既に囲まれていれば外す。
    public func toggleWrap(_ delimiter: String) {
        guard let (text, selection) = readState() else { return }
        applyTransform(MarkdownFormatting.wrap(text: text, selection: selection, delimiter: delimiter))
    }

    /// 選択行に接頭辞を付ける。全行が既に持っていれば外す。
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

    // MARK: - 独自コマンド

    /// 現在のドキュメントテキストとセレクション。テキストビュー未接続なら `nil`。
    ///
    /// `MarkdownFormatting` の純関数と組み合わせて独自コマンドを組み立てる:
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

    /// 変換をテキストビューに適用する。
    ///
    /// 標準コマンド（``toggleBold()`` など）もこれを経由する。undo は
    /// システムの `UndoManager` が担うため、適用結果はそのまま取り消せる。
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
