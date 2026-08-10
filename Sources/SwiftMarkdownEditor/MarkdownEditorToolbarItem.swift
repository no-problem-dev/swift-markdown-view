import SwiftUI
import SwiftMarkdownEditorTextKit

/// One item in the formatting toolbar.
///
/// Pass an ordered array to
/// ``MarkdownEditor/init(text:mode:baseFontSize:livePreview:inputRules:toolbar:controller:)``.
/// The default is `.standard`:
///
/// ```swift
/// MarkdownEditor(text: $text, toolbar: .standard)
/// ```
///
/// You can also keep part of the default set and add commands of your own:
///
/// ```swift
/// MarkdownEditor(text: $text, toolbar: [
///     .bold, .italic,
///     .separator,
///     .item(icon: "highlighter", label: "Highlight", key: "h") { controller in
///         guard let state = controller.state else { return }
///         controller.apply(MarkdownFormatting.wrap(
///             text: state.text, selection: state.selection, delimiter: "=="
///         ))
///     }
/// ])
/// ```
///
/// `label` has no default. An icon-only button has no spoken name, so leaving the
/// label out would make the items indistinguishable under VoiceOver. Passing `key`
/// adds a keyboard shortcut, which works on macOS and on iPad with a hardware
/// keyboard.
///
/// - Important: The shortcut is registered by the rendered toolbar button, so it is
///   live only while the item is on screen. Passing `toolbar: []` hides the toolbar,
///   and ``MarkdownEditorMode/preview`` hides it as well; the shortcuts go with it.
public struct MarkdownEditorToolbarItem: Identifiable, Sendable {

    /// A stable key that identifies the item across view updates.
    ///
    /// SwiftUI uses it to diff the toolbar. When ``item(id:icon:label:key:modifiers:action:)``
    /// is called without an `id`, it is derived from the icon name and the label.
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

    /// Creates a toolbar item of your own.
    ///
    /// - Parameters:
    ///   - id: A stable identifier. Derived from the icon name and the label when omitted.
    ///   - icon: An SF Symbols name.
    ///   - label: The accessibility label, spoken by VoiceOver in place of the icon.
    ///   - key: A keyboard shortcut, or `nil` for none.
    ///   - modifiers: The modifier keys the shortcut is pressed with.
    ///   - action: Runs when the button is pressed, receiving the editor's controller.
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

    /// A vertical rule that separates groups of items.
    public static let separator = MarkdownEditorToolbarItem(id: "separator", kind: .separator)
}

// MARK: - Default items

// The labels below are Japanese literals, and VoiceOver speaks them as written.
// Apps shipping in another language should build their items with `item(...)`.

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

// MARK: - Default arrangement

public extension Array where Element == MarkdownEditorToolbarItem {

    /// The standard toolbar: four inline styles, a separator, then heading, list, quote, and link.
    static var standard: [MarkdownEditorToolbarItem] {
        [
            .bold, .italic, .strikethrough, .inlineCode,
            .separator,
            .heading, .bulletList, .quote, .link
        ]
    }
}
