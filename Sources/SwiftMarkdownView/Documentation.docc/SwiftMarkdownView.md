# ``SwiftMarkdownView``

A SwiftUI-native Markdown rendering library with DesignSystem integration.

@Metadata {
    @PageColor(blue)
}

## Overview

`SwiftMarkdownView` renders Markdown text as a native SwiftUI view. It supports CommonMark and GitHub Flavored Markdown, including tables, task lists, aside callouts, Mermaid diagrams, and math expressions. On iOS and macOS the library uses a single TextKit 2 text view so selection and copy work continuously across block boundaries.

The library integrates with `swift-design-system` out of the box: typography tokens, color palette, and spacing scale all flow through the SwiftUI environment, so your Markdown automatically matches the rest of your app's visual language.

Optional add-on modules extend the core without adding mandatory dependencies. `SwiftMarkdownViewHighlightJS` brings HighlightJS syntax highlighting for 50+ languages; `SwiftMarkdownViewLaTeX` adds LaTeX math typesetting; `SwiftMarkdownEditor` provides a full Markdown editor with live preview.

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
