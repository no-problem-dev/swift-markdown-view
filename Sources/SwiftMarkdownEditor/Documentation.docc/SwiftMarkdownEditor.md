# ``SwiftMarkdownEditor``

A SwiftUI Markdown editor with live syntax highlighting, a formatting toolbar, and an optional rendered preview.

@Metadata {
    @PageColor(orange)
}

## Overview

`SwiftMarkdownEditor` provides `MarkdownEditor`, a drop-in SwiftUI `View` that wraps a TextKit 2 text view for source editing and reuses `MarkdownView` for the rendered preview. The plain Markdown string bound to the view is always the single source of truth — no intermediate representation is exposed.

The editor supports three presentation modes controlled by `MarkdownEditorMode`. In `.edit` mode the source is shown with live syntax highlighting applied by the underlying TextKit 2 layout manager. In `.preview` mode the rendered `MarkdownView` fills the content area. In `.split` mode — best on macOS and wide iPad layouts — both panels appear side by side, separated by a divider. The user switches between modes using a segmented control in the editor header.

A scrollable formatting toolbar sits below the mode switcher in `.edit` and `.split` modes. Each button applies a formatting transform — bold, italic, strikethrough, inline code, heading promotion, bullet list, blockquote, and link insertion — to the selected range in the source text view.

Autoformatting input rules fire automatically as the user types. The default rule set continues list items on return and wraps selected text in paired Markdown delimiters. Pass a custom `InputRuleProcessor` to the initialiser to extend or replace the rules.

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

Colors and spacing come from the `swift-design-system` theme in the SwiftUI environment, so the editor matches the rest of your app automatically.

## Topics

### Editor View

- ``MarkdownEditor``
- ``MarkdownEditorMode``
