# ``SwiftMarkdownView``

A SwiftUI-native Markdown rendering library with DesignSystem integration.

@Metadata {
    @PageColor(blue)
}

## Overview

`SwiftMarkdownView` renders Markdown text as a native SwiftUI view. It supports CommonMark and GitHub Flavored Markdown, including tables, task lists, aside callouts, Mermaid diagrams, and math expressions. On iOS and macOS the library uses a single TextKit 2 text view so selection and copy work continuously across block boundaries.

The library integrates with `swift-design-system` out of the box: typography tokens, color palette, and spacing scale all flow through the SwiftUI environment, so your Markdown automatically matches the rest of your app's visual language.

`SwiftMarkdownView` is the core of a four-module family. Import only the products you need — each add-on is an independent library product with no mandatory dependencies on the others.

```swift
import SwiftUI
import SwiftMarkdownView

struct ArticleView: View {
    let markdown: String

    var body: some View {
        ScrollView {
            MarkdownView(markdown)
                .padding()
        }
    }
}
```

`SwiftMarkdownViewHighlightJS` adds accurate syntax highlighting for 50+ programming languages, powered by HighlightSwift. It ships a rich collection of light and dark themes — Xcode, GitHub, Atom One, Solarized, Tokyo Night, and the accessible `a11y` series — and automatically pairs them with the system color scheme via `.adaptiveSyntaxHighlighting()`. Import `SwiftMarkdownViewHighlightJS` whenever your Markdown is likely to include code blocks and plain monospace output is not sufficient.

`SwiftMarkdownViewLaTeX` upgrades inline `$...$` and block `$$...$$` math expressions from plain source text to real LaTeX typesetting via the SwiftMath engine. Inline math flows naturally inside the surrounding `Text` run; display math renders as a full-width block. Activate it by injecting `.mathRenderer(LaTeXMathRenderer())` into the view hierarchy. Import `SwiftMarkdownViewLaTeX` whenever your Markdown may contain mathematical notation.

`SwiftMarkdownEditor` provides a full Markdown authoring experience. `MarkdownEditor` wraps a TextKit 2 source editor with live syntax highlighting, a scrollable formatting toolbar, and an optional side-by-side preview pane that reuses `MarkdownView` internally. The plain Markdown string is always the single source of truth. Import `SwiftMarkdownEditor` to add authoring capability alongside rendering.

The module layout:

```
SwiftMarkdownView (core renderer — this module)
  ├── SwiftMarkdownViewHighlightJS  → HighlightJSSyntaxHighlighter, .adaptiveSyntaxHighlighting()
  ├── SwiftMarkdownViewLaTeX        → LaTeXMathRenderer
  └── SwiftMarkdownEditor           → MarkdownEditor, MarkdownEditorMode
```

```swift
import SwiftUI
import SwiftMarkdownView

struct ArticleView: View {
    let markdown: String

    var body: some View {
        ScrollView {
            MarkdownView(markdown)
                .padding()
        }
    }
}
```

## Topics

### Essentials

- <doc:GettingStarted>

### Views

- ``MarkdownView``
- ``HighlightedCodeView``

### Content Model

- ``MarkdownContent``
- ``MarkdownBlock``
- ``MarkdownInline``

### Syntax Highlighting

- ``SyntaxHighlighter``
- ``PlainTextHighlighter``
- ``HighlightState``
- <doc:SyntaxHighlighting>

### Aside Callouts

- ``AsideStyle``
- ``DefaultAsideStyle``
- ``AsideKind``
- <doc:Asides>

### Code Block Styling

- ``CodeBlockStyle``
- ``DefaultCodeBlockStyle``
- ``MinimalCodeBlockStyle``
- ``TerminalCodeBlockStyle``

### Heading Styling

- ``HeadingStyle``
- ``DefaultHeadingStyle``
- ``CompactHeadingStyle``
- ``ColoredHeadingStyle``
- ``DividedHeadingStyle``

### Link Styling

- ``LinkStyle``
- ``DefaultLinkStyle``
- ``SubtleLinkStyle``
- ``BoldLinkStyle``
- ``ClassicLinkStyle``
- ``MonochromeLinkStyle``

### Table Styling

- ``TableStyle``
- ``DefaultTableStyle``
- ``StripedTableStyle``
- ``BorderlessTableStyle``
- ``CardTableStyle``

### Rendering Options

- ``MarkdownRenderingOptions``

### Math

- ``MathRenderer``
- ``PlainMathRenderer``

### Mermaid Diagrams

- ``MermaidScriptProvider``
- ``MermaidScriptSource``
- ``CDNMermaidScriptProvider``
- ``BundledMermaidScriptProvider``
- ``AdaptiveMermaidView``
- ``MermaidFallbackView``
- <doc:MermaidDiagrams>

### Domain Types

- ``TableData``
- ``ListItem``
