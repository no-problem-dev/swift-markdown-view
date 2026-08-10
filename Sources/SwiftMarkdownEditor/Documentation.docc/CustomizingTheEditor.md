# Customizing the Editor

Build your own toolbar, drive the editor from elsewhere in your UI, add input rules, and change
the source colors.

## Overview

Four extension points cover most of what an app needs to change: the toolbar's contents, an
injected controller for driving the editor from outside it, the input rules that fire as the user
types, and the theme that colors the source. They compose — a custom toolbar item can call into
the same controller your own buttons use.

## The toolbar

The toolbar is an ordered array of items. `.standard` is the built-in set; take part of it and add
your own commands:

```swift
MarkdownEditor(text: $text, toolbar: [
    .bold, .italic,
    .separator,
    .item(icon: "highlighter", label: "Highlight", key: "h") { controller in
        guard let state = controller.state else { return }
        controller.apply(MarkdownFormatting.wrap(
            text: state.text, selection: state.selection, delimiter: "=="
        ))
    }
])
```

`label` is not optional, and that is on purpose. An icon-only button has no spoken name, so
without it a VoiceOver user meets a row of buttons that all announce the same nothing.

Passing `key` adds a keyboard shortcut, which works on macOS and on iPad with a hardware keyboard.
Shortcuts come from the item definitions rather than from a separate table, so replacing the
toolbar cannot silently drop them.

Pass `[]` to hide the toolbar entirely — worth doing when your app already has its own formatting
UI, which the next section covers.

## Driving the editor from your own UI

Inject a controller to send commands from anywhere, and bind `mode` to observe or set the current
view mode:

```swift
struct EditorScreen: View {
    @State private var text = ""
    @State private var mode: MarkdownEditorMode = .edit
    @StateObject private var controller = MarkdownEditorController()

    var body: some View {
        VStack {
            Button("Bold") { controller.toggleBold() }
            MarkdownEditor(text: $text, mode: $mode, toolbar: [], controller: controller)
        }
    }
}
```

The controller offers the common commands directly — `toggleBold()`, `toggleItalic()`,
`toggleInlineCode()`, `toggleStrikethrough()`, `toggleHeading()`, `toggleQuote()`,
`toggleBulletList()`, `insertLink()` — plus `undo()`, `redo()`, and the `canUndo` / `canRedo`
flags you need to enable and disable your own buttons.

For anything beyond that, `controller.state` gives you the current text and selection, and
`controller.apply(_:)` applies an `EditTransform`. Together with the pure functions in
`MarkdownFormatting` — `wrap(text:selection:delimiter:)`, `toggleLinePrefix(text:selection:prefix:)`,
`insertLink(text:selection:urlPlaceholder:)` — that is enough to write any command. Undo and redo
are handled by the system `UndoManager`, so your commands are undoable without extra work.

`controller.state` is optional: it is `nil` until the controller is bound to a live text view.
Guard it rather than force-unwrapping, as the example in the previous section does.

## Input rules

Input rules run as the user types — continuing a list on Return, wrapping a selection when `*` is
typed. Conform to `InputRule` to add your own:

```swift
struct MyRule: InputRule {
    func transform(state: EditorState, inserting text: String, replacing range: TextSpan) -> RuleTransform? {
        // Return nil to let the next rule try.
    }
}

MarkdownEditor(
    text: $text,
    inputRules: InputRuleProcessor(rules: [MyRule()] + InputRuleProcessor.standard.rules)
)
```

Rules are tried in order and the first match wins, so putting yours ahead of the standard set lets
it pre-empt a built-in behaviour, and putting it after lets it act only on input nothing else
claimed.

## Source colors

Source highlighting colors come from `MarkdownEditorTheme`. The default is built from system
semantic colors and follows light and dark automatically. Change one token, or build a theme from
its four roles:

```swift
var theme = MarkdownEditorTheme.light
theme.styles[.linkURL] = .init(color: .systemPurple, italic: true)

MarkdownEditor(text: $text)
    .markdownEditorTheme(theme)
```

Set the editor's font size through `MarkdownEditor`'s own `baseFontSize` parameter. The theme
carries a `baseFontSize` too, but `MarkdownEditor` overrides it with the value from its
initializer, so setting it on the theme has no effect there.

If your app themes itself with `swift-design-system`, add the `SwiftMarkdownEditorDesignSystem`
product and apply `.markdownEditorDesignSystemTheme()` instead of building a theme by hand.

## Find and replace on macOS

The source editor enables the standard find bar, but <kbd>⌘F</kbd> is routed through the host
app's Edit menu, and SwiftUI's default menu bar does not include Find. Declare it in your `App`:

```swift
WindowGroup {
    EditorScreen()
}
.commands { TextEditingCommands() }
```

Without this the find bar never appears, even though the editor is ready for it.

## Topics

### Toolbar

- ``MarkdownEditorToolbarItem``
- ``MarkdownFormattingToolbar``

### Modes

- ``MarkdownEditorMode``
