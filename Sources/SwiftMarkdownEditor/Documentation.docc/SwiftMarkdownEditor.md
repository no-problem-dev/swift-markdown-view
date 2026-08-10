# ``SwiftMarkdownEditor``

A SwiftUI Markdown editor with live syntax highlighting, a formatting toolbar, and a rendered
preview.

@Metadata {
    @PageColor(orange)
}

## Overview

`MarkdownEditor` is a drop-in `View` that binds to a plain `String`. There is no document type to
build, no intermediate model to convert to and from, and nothing to serialise on save — the
Markdown text is the state, and it stays the single source of truth from the moment the user
types.

```swift
import SwiftUI
import SwiftMarkdownEditor

struct NoteEditor: View {
    @State private var source = "# My Note\n\nStart writing…"

    var body: some View {
        MarkdownEditor(text: $source)
    }
}
```

It runs the same way on iOS and macOS. The macOS side is a real `NSTextView` implementation rather
than a compatibility shim over the iOS path, so the platform behaviours users expect — the find
bar, the standard editing menus, keyboard shortcuts — are the system's own.

Three view modes are available. `.edit` shows the source with live highlighting; `.preview`
renders the document with `MarkdownView`; `.split` shows both side by side, which suits macOS
windows and wide iPad layouts. The built-in mode picker offers `.split` on macOS only, though the
mode itself works anywhere you set it.

Turning on live preview changes what editing looks like rather than adding a second pane: inline
markers are hidden and the text renders in place as you type, while the line holding the caret
keeps its markers so you can still edit them.

Everything the toolbar does is also available as a plain function. The editing commands are pure
transforms over text and selection, so a command you add from your own UI is the same kind of
thing as a built-in one — and undo works for both, because both go through the system
`UndoManager`.

See <doc:CustomizingTheEditor> for toolbars, controllers, input rules, and theming.

## Topics

### Essentials

- ``MarkdownEditor``
- ``MarkdownEditorMode``
- <doc:CustomizingTheEditor>

### Toolbar

- ``MarkdownEditorToolbarItem``
- ``MarkdownFormattingToolbar``
