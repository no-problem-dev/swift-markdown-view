// The semantic model (MarkdownContent / MarkdownBlock / MarkdownInline / table &
// list types) lives in the UI-free `MarkdownModel` target so the SwiftUI renderer,
// the TextKit renderer, and the editor can all share it without pulling in SwiftUI.
// Re-export it so `import SwiftMarkdownView` keeps vending those types unchanged.
@_exported import MarkdownModel

// The TextKit rendering layer (theme, attachment/highlighter protocols, and the
// `MarkdownSelectableText` view's `MarkdownTextTheme`) lives in
// `MarkdownAttributedKit`. Re-export it so the public selectable-text API is
// usable from `import SwiftMarkdownView` alone.
@_exported import MarkdownAttributedKit
