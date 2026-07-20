import SwiftUI
import SwiftMarkdownEditorCore
import SwiftMarkdownEditorRules

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// TextKit 2 の `UITextView`/`NSTextView` をラップした SwiftUI コンポーネント。
/// Markdown ソースをライブシンタックスハイライト付きで編集する。
///
/// 設計上の注意（エディタ戦略より）:
/// - TextKit 2（`usingTextLayoutManager: true`）上に構築。`.layoutManager` には触れず、
///   これを触ると TextKit 1 に静かにフォールバックする。
/// - ハイライトは属性のみで変更時に再適用し、セレクションを保持する。
/// - Markdown のスマートクォート・ダッシュは無効化 — `*`/`-`/`"` の構文を破壊するため。
/// - オートフォーマット（リスト継続・スマートラッピング）はルール層の
///   純粋な ``InputRuleProcessor`` を通じてルーティングされる。
public struct MarkdownSourceTextView {

    @Binding public var text: String
    public var theme: MarkdownEditorTheme
    public var inputRules: InputRuleProcessor
    public var isEditable: Bool
    /// `true` のとき、インラインマーカーを非表示にしてソースをインプレースレンダリングする
    /// （Notion スタイルのライブプレビュー）。キャレットが触れる行ではマーカーが表示される。
    /// `false` のときマーカーはソースハイライト付きで表示される。
    public var livePreview: Bool
    /// テキストビューが作成されたときに受け取るコールバック
    /// （SwiftUI ツールバーからコントローラがフォーマットアクションを操作できるようにする）。
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

    /// スタイルに影響する入力のハッシュ。`updateUIView`/`updateNSView` はこれが変わったときのみ再スタイルし、
    /// レイアウトパスのたびに実行しない。
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

    /// 新しいテキスト長に収まるように選択範囲を切り詰める。
    ///
    /// 親がテキストを差し替えたときに使う。差分が分からないので厳密な位置写像はできないが、
    /// 収まる選択をわざわざ捨てる理由はない。長さを無条件に 0 にすると、正規化・整形・
    /// 外部 undo・再読込のたびにユーザーの選択が消える。
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
        /// 自分でテキストをセットしている間の再入バインディング更新を防ぐ。
        var isApplyingProgrammaticChange = false
        /// 最後に適用したスタイル入力。`updateUIView`/`updateNSView` の冪等性を保つため使用。
        /// テーマ・モードが実際に変わったときのみ再スタイルし、レイアウトパスのたびには実行しない
        /// （スナップショット計測中のループを防ぐ）。
        var appliedStyleSignature: Int?

        init(text: Binding<String>, theme: MarkdownEditorTheme, inputRules: InputRuleProcessor, livePreview: Bool) {
            self.text = text
            self.theme = theme
            self.inputRules = inputRules
            self.livePreview = livePreview
        }

        /// `storage` にスタイルをインプレースで適用する。ライブプレビューモードでは
        /// `selection`/`focused` に応じてマーカーを非表示・表示する。
        /// それ以外ではプレーンなソースハイライトを適用する。
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

        /// `selection` を保持したままスタイルを再適用する。
        func rehighlight(_ storage: NSTextStorage, selection: NSRange, focused: Bool, restore: (NSRange) -> Void) {
            applyStyling(to: storage, selection: selection, focused: focused)
            restore(selection)
        }

        /// 保留中の編集に対応する入力ルール変換を解決する。該当がない場合は `nil`。
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
        // 検索・置換。最低要件が iOS 17 なので標準の Find interaction をそのまま使える。
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
        // 選択を長さごと保てる範囲で保つ。無条件に length 0 へ潰すと、親がテキストを
        // 書き換えるたびにユーザーの選択が消える。差分が分からないので厳密な写像はできないが、
        // 新しいテキストに収まる選択をわざわざ捨てる理由はない。
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
        // 変換途中（未確定文字列がある状態）では入力ルールを動かさない。
        // ここで false を返すと合成セッションを外から壊し、変換候補が消える。
        guard textView.markedTextRange == nil else { return true }
        guard let transform = ruleTransform(currentText: textView.text, replacing: range, with: replacement) else {
            return true
        }
        apply(transform, to: textView)
        return false
    }

    public func textViewDidChange(_ textView: UITextView) {
        guard !isApplyingProgrammaticChange else { return }
        // 未確定文字列は下線・変換節ハイライトを属性として持つ。全域に属性を貼り直すと
        // それらを巻き込んで消してしまう。未確定のかなを親の状態へ流さないためでもある。
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

        // 検索・置換。標準の Find bar をそのまま使う。
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
        // iOS 側と同じく、収まる範囲で選択を保つ。ここには復元処理自体が無かった。
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
