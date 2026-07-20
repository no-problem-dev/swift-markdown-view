# SwiftMarkdownView

English | [日本語](./README.ja.md)

A SwiftUI-native Markdown rendering library.

![Swift 6.2+](https://img.shields.io/badge/Swift-6.2+-orange.svg)
![iOS 17+](https://img.shields.io/badge/iOS-17+-blue.svg)
![macOS 14+](https://img.shields.io/badge/macOS-14+-purple.svg)
![License](https://img.shields.io/badge/License-MIT-green.svg)

## Features

- **Renderer and editor in one package**: `MarkdownEditor` gives you a live-preview Markdown
  editor built on the same rendering engine — source highlighting, input rules for lists and
  emphasis, and a split preview on macOS
- **SwiftUI Native**: High-performance rendering using `NSTextStorage` + TextKit 2
- **Continuous selection**: The whole document renders into one text view, so selection runs
  across blocks and Copy yields readable text
- **Rich Element Support**: Tables, task lists, images, Mermaid diagrams, math (LaTeX), and more
- **Optional Syntax Highlighting**: 50+ languages via separate HighlightJS module
- **No design-system lock-in**: Colors, metrics, and type sizes are plain protocols you implement.
  Defaults use system semantic colors and adapt to light/dark automatically
- **Optional `swift-design-system` bridge**: Add `SwiftMarkdownViewDesignSystem` if your app already
  uses it, and Markdown follows your app theme

## Quick Start

```swift
import SwiftUI
import SwiftMarkdownView

struct ContentView: View {
    var body: some View {
        MarkdownView("""
        # Hello, Markdown!

        This is a **bold** and *italic* text.

        ```swift
        let greeting = "Hello, World!"
        print(greeting)
        ```

        - [x] Task completed
        - [ ] Task pending
        """)
    }
}
```

## Installation

### Swift Package Manager

Add to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/no-problem-dev/swift-markdown-view.git", from: "3.0.0")
]
```

Add to your target:

```swift
.target(
    name: "YourTarget",
    dependencies: [
        .product(name: "SwiftMarkdownView", package: "swift-markdown-view"),
        // For syntax highlighting (optional)
        .product(name: "SwiftMarkdownViewHighlightJS", package: "swift-markdown-view")
    ]
)
```

## Supported Elements

### Block Elements

| Element | Markdown | Notes |
|---------|----------|-------|
| Headings | `# H1` ~ `###### H6` | Typography integration |
| Paragraphs | text | |
| Code Blocks | ` ```swift ``` ` | Optional highlighting |
| Asides | `> Note: text` | 24 kinds + custom |
| Mermaid | ` ```mermaid ``` ` | iOS 26+ recommended |
| Math | `$$...$$` / ` ```math ``` ` | LaTeX display math |
| Unordered Lists | `- item` | Nested supported |
| Ordered Lists | `1. item` | Nested supported |
| Task Lists | `- [x] done` | |
| Tables | `\| col \|` | Alignment supported |
| Thematic Breaks | `---` | |

### Inline Elements

| Element | Markdown |
|---------|----------|
| Emphasis (italic) | `*text*` |
| Strong (bold) | `**text**` |
| Inline Code | `` `code` `` |
| Links | `[text](url)` |
| Images | `![alt](url)` |
| Strikethrough | `~~text~~` |
| Inline Math | `$...$` / `\(...\)` |

## Syntax Highlighting

### Default Behavior

By default, code blocks are displayed without highlighting.

### HighlightJS Highlighting

To enable syntax highlighting with 50+ languages, use the optional module:

```swift
import SwiftMarkdownView
import SwiftMarkdownViewHighlightJS

// Recommended: Adaptive highlighting (auto light/dark mode)
MarkdownView(source)
    .adaptiveSyntaxHighlighting()

// With specific theme
MarkdownView(source)
    .adaptiveSyntaxHighlighting(theme: .github)

// Manual configuration
MarkdownView(source)
    .markdownSyntaxHighlighter(
        HighlightJSSyntaxHighlighter(theme: .atomOne, colorMode: .dark)
    )
```

**Available Themes**: `.a11y` (accessibility recommended), `.xcode`, `.github`, `.atomOne`, `.solarized`, `.tokyoNight`

### Custom Highlighter

Implement your own highlighting logic:

```swift
struct MyHighlighter: SyntaxHighlighter {
    func highlight(_ code: String, language: String?) async throws -> AttributedString {
        var result = AttributedString(code)
        // Custom implementation
        return result
    }
}

MarkdownView(source)
    .markdownSyntaxHighlighter(MyHighlighter())
```

## Asides (Callouts)

Blockquotes are interpreted as callouts such as Note, Warning, and Tip.

```swift
MarkdownView("""
> Note: This is supplementary information.

> Warning: This requires attention.

> Tip: Here's a helpful tip.
""")
```

**Supported Kinds**: `Note`, `Tip`, `Important`, `Warning`, `Experiment`, `Attention`, `Bug`, `ToDo`, `SeeAlso`, `Throws`, and 24 more + custom

## Mermaid Diagrams

Code blocks with `mermaid` language are rendered as diagrams.

```swift
MarkdownView("""
```mermaid
graph TD
    A[Start] --> B{Decision}
    B -->|Yes| C[OK]
    B -->|No| D[Cancel]
```
""")
```

**Supported Diagrams**: flowchart, sequence, class, state, gantt, journey, timeline, mindmap

**Requirements**:
- iOS 26+, macOS 26+: Native WebKit rendering
- Earlier versions: Fallback display (shown as code block)

## Theming

The defaults use system semantic colors, so text stays readable in both light and dark mode
without any setup. To match your own design, implement `MarkdownPalette` — no external
dependency is involved:

```swift
import SwiftMarkdownView

struct BrandPalette: MarkdownPalette {
    var text: Color { .primary }
    var secondaryText: Color { .secondary }
    var heading: Color { .indigo }
    var link: Color { .blue }
    var codeBackground: Color { Color.gray.opacity(0.12) }
    var rule: Color { Color.gray.opacity(0.4) }
}

MarkdownView("# Themed Markdown")
    .markdownPalette(BrandPalette())
```

`MarkdownMetrics` (paragraph spacing, indent step) and `MarkdownTypeScale` (body and heading
sizes) work the same way via `.markdownMetrics(_:)` and `.markdownTypeScale(_:)`.

### Using swift-design-system

If your app already uses `swift-design-system`, add the `SwiftMarkdownViewDesignSystem` product
and Markdown follows your app theme:

```swift
import DesignSystem
import SwiftMarkdownView
import SwiftMarkdownViewDesignSystem

MarkdownView("# Themed Markdown")
    .markdownTheme(themeProvider)
```

For the editor, the equivalent is `SwiftMarkdownEditorDesignSystem` and
`.markdownEditorDesignSystemTheme()`.

> `swift-design-system` is still resolved as a package dependency because the optional bridge,
> LaTeX, and catalog modules use it. What changed is that `SwiftMarkdownView` and
> `SwiftMarkdownEditor` no longer link or expose it, so your code never has to touch its types.

## Module Structure

| Module | Role |
|--------|------|
| `SwiftMarkdownView` | SwiftUI view entry point; includes `MarkdownModel` and `MarkdownAttributedKit` (re-exported) |
| `SwiftMarkdownEditor` | Markdown editor with live preview |
| `SwiftMarkdownViewHighlightJS` | Optional HighlightJS syntax highlighting |
| `SwiftMarkdownViewLaTeX` | Optional LaTeX math rendering |
| `SwiftMarkdownViewDesignSystem` | Optional bridge that maps `swift-design-system` tokens onto Markdown theming |
| `SwiftMarkdownEditorDesignSystem` | Same bridge for the editor theme |
| `SwiftMarkdownViewCatalog` | Demo screens showing every supported element. Not needed to use the library |

## Dependencies

| Package | Purpose | Required |
|---------|---------|----------|
| [swift-markdown](https://github.com/swiftlang/swift-markdown) | Markdown parsing | Yes |
| [swift-design-system](https://github.com/no-problem-dev/swift-design-system) | Design tokens — `SwiftMarkdownView` resolves colors, typography, spacing and radii through it | Yes |
| [HighlightSwift](https://github.com/appstefan/HighlightSwift) | Syntax highlighting | Only with `SwiftMarkdownViewHighlightJS` |
| [swift-latex-view](https://github.com/no-problem-dev/swift-latex-view) | LaTeX typesetting (pulls in [SwiftMath](https://github.com/mgriebling/SwiftMath)) | Only with `SwiftMarkdownViewLaTeX` |
| [swift-visual-testing](https://github.com/no-problem-dev/swift-visual-testing) | Snapshot testing | Tests only |
| [swift-docc-plugin](https://github.com/apple/swift-docc-plugin) | Documentation generation | Build tooling only |

`swift-design-system` is a hard dependency of the core library, not an optional add-on.
If you only need Markdown rendering, be aware that it comes along.

## Examples

Runnable sample apps live in [`Examples/`](./Examples):

- [`MarkdownPlayground`](./Examples/MarkdownPlayground) — iOS and macOS app exercising
  rendering, theming, and cross-block selection
- [`ZennArticleSwiftUI`](./Examples/ZennArticleSwiftUI) — rendering a real long-form article

## Documentation

- **API Reference**: [DocC Documentation](https://no-problem-dev.github.io/swift-markdown-view/documentation/swiftmarkdownview/)

## License

MIT License - See [LICENSE](LICENSE) for details.
