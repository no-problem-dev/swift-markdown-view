# ``SwiftMarkdownView``

Render Markdown as native SwiftUI, with selection and Copy that work across the whole document.

@Metadata {
    @PageColor(blue)
}

## Overview

`SwiftMarkdownView` parses CommonMark and GitHub Flavored Markdown — tables, task lists,
strikethrough — and adds aside callouts, Mermaid diagrams, and math on top.

What separates it from a stack of SwiftUI views per block is that the whole document is composed
into one attributed string and drawn by a single TextKit 2 text view. A selection can therefore
start in a heading, run through a code block, and end inside a table, and Copy yields text a
person can read rather than a slice of layout. Images, display math, and diagrams ride along as
attachments inside that same text view, so they stay inside the selection instead of interrupting
it.

Nothing about the appearance is inherited from an external design system. Colors, spacing, and
type sizes are three small protocols you can implement, and the defaults are built from system
semantic colors, so text is legible in light and dark before you configure anything. If your app
already uses `swift-design-system`, a separate bridge product maps its tokens across.

Highlighting and LaTeX typesetting are separate products for the same reason: the core should not
carry a dependency that most documents never need. Add them when your Markdown actually contains
fenced code or math.

To write Markdown as well as read it, add the `SwiftMarkdownEditor` product. It reuses this
renderer for its preview pane, and a plain Markdown `String` remains the single source of truth
throughout.

## Topics

### Essentials

- <doc:GettingStarted>
- <doc:SupportedElements>
- <doc:ModuleStructure>

### Views

- ``MarkdownView``
- ``MarkdownSelectableText``
- ``HighlightedCodeView``
- ``MathText``

### Appearance

- <doc:Theming>
- ``MarkdownPalette``
- ``DefaultMarkdownPalette``
- ``MarkdownMetrics``
- ``DefaultMarkdownMetrics``
- ``MarkdownTypeScale``
- ``DefaultMarkdownTypeScale``

### Syntax highlighting

- <doc:SyntaxHighlighting>
- ``SyntaxHighlighter``
- ``PlainTextHighlighter``
- ``HighlightState``

### Aside callouts

- <doc:Asides>

### Math

- ``MathRenderer``
- ``PlainMathRenderer``
- ``MarkdownRenderingOptions``

### Mermaid diagrams

- <doc:MermaidDiagrams>
- ``MermaidScriptProvider``
- ``MermaidScriptSource``
- ``CDNMermaidScriptProvider``
- ``BundledMermaidScriptProvider``

### Images

- ``MarkdownImagePolicy``
