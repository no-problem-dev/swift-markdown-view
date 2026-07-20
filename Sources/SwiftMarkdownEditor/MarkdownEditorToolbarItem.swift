import SwiftUI
import SwiftMarkdownEditorTextKit

/// フォーマットツールバーに並ぶ 1 項目。
///
/// ``MarkdownEditor/init(text:mode:baseFontSize:livePreview:inputRules:toolbar:controller:)``
/// に順序付き配列で渡す。既定は ``standard``:
///
/// ```swift
/// MarkdownEditor(text: $text, toolbar: .standard)
/// ```
///
/// 既定の一部だけ使い、独自コマンドを足すこともできる:
///
/// ```swift
/// MarkdownEditor(text: $text, toolbar: [
///     .bold, .italic,
///     .separator,
///     .item(icon: "highlighter", label: "マーカー", key: "h") { controller in
///         guard let state = controller.state else { return }
///         controller.apply(MarkdownFormatting.wrap(
///             text: state.text, selection: state.selection, delimiter: "=="
///         ))
///     }
/// ])
/// ```
///
/// `label` は省略できない。アイコンだけのボタンには読み上げ名が無く、
/// 付け忘れると VoiceOver で項目が区別できなくなるため。
/// `key` を与えるとキーボードショートカットも付く。ショートカットは項目定義から
/// 供給されるので、ツールバーを差し替えても失われない。
public struct MarkdownEditorToolbarItem: Identifiable, Sendable {

    /// 同一項目を識別するキー。SwiftUI の差分計算に使う。
    public let id: String

    let kind: Kind

    enum Kind: Sendable {
        case button(Button)
        case separator
    }

    struct Button: Sendable {
        let icon: String
        let label: String
        let key: KeyEquivalent?
        let modifiers: EventModifiers
        let action: @Sendable @MainActor (MarkdownEditorController) -> Void
    }

    /// 独自のツールバー項目を作る。
    ///
    /// - Parameters:
    ///   - id: 識別子。省略するとアイコン名とラベルから導出する。
    ///   - icon: SF Symbols 名。
    ///   - label: 読み上げラベル。必須。
    ///   - key: キーボードショートカット。`nil` なら付けない。
    ///   - modifiers: ショートカットの修飾キー。既定は `.command`。
    ///   - action: 押下時に実行する処理。エディタのコントローラを受け取る。
    public static func item(
        id: String? = nil,
        icon: String,
        label: String,
        key: KeyEquivalent? = nil,
        modifiers: EventModifiers = .command,
        action: @escaping @Sendable @MainActor (MarkdownEditorController) -> Void
    ) -> MarkdownEditorToolbarItem {
        MarkdownEditorToolbarItem(
            id: id ?? "\(icon)|\(label)",
            kind: .button(Button(icon: icon, label: label, key: key, modifiers: modifiers, action: action))
        )
    }

    /// 項目のグループを区切る縦線。
    public static let separator = MarkdownEditorToolbarItem(id: "separator", kind: .separator)
}

// MARK: - 既定の項目

public extension MarkdownEditorToolbarItem {

    static let bold = item(id: "bold", icon: "bold", label: "太字", key: "b") { $0.toggleBold() }

    static let italic = item(id: "italic", icon: "italic", label: "斜体", key: "i") { $0.toggleItalic() }

    static let strikethrough = item(
        id: "strikethrough",
        icon: "strikethrough",
        label: "取り消し線",
        key: "x",
        modifiers: [.command, .shift]
    ) { $0.toggleStrikethrough() }

    static let inlineCode = item(
        id: "inlineCode",
        icon: "curlybraces",
        label: "インラインコード",
        key: "e"
    ) { $0.toggleInlineCode() }

    static let heading = item(id: "heading", icon: "number", label: "見出し") { $0.toggleHeading() }

    static let bulletList = item(
        id: "bulletList",
        icon: "list.bullet",
        label: "箇条書き"
    ) { $0.toggleBulletList() }

    static let quote = item(id: "quote", icon: "text.quote", label: "引用") { $0.toggleQuote() }

    static let link = item(id: "link", icon: "link", label: "リンクを挿入", key: "k") { $0.insertLink() }
}

// MARK: - 既定の並び

public extension Array where Element == MarkdownEditorToolbarItem {

    /// 標準のツールバー構成。インライン装飾 4 つ、区切り、ブロック操作 4 つ。
    static var standard: [MarkdownEditorToolbarItem] {
        [
            .bold, .italic, .strikethrough, .inlineCode,
            .separator,
            .heading, .bulletList, .quote, .link
        ]
    }
}
