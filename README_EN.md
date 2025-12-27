# SwiftMarkdownView

English | [日本語](README.md)

A SwiftUI-native Markdown rendering library. Integrates with DesignSystem and provides beautiful Markdown display with syntax highlighting.

![Swift 6.0+](https://img.shields.io/badge/Swift-6.0+-orange.svg)
![iOS 17+](https://img.shields.io/badge/iOS-17+-blue.svg)
![macOS 14+](https://img.shields.io/badge/macOS-14+-purple.svg)
![License](https://img.shields.io/badge/License-MIT-green.svg)

## Features

- **SwiftUI Native**: High-performance rendering using `AttributedString` and `Text` concatenation
- **DesignSystem Integration**: Seamless integration with ColorPalette, Typography, and Spacing
- **Syntax Highlighting**: 15 languages supported (Swift, TypeScript, Python, Go, Rust, etc.)
- **Rich Element Support**: Tables, task lists, images, code blocks, and more
- **Customizable**: Style configuration through environment values

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
    .package(url: "https://github.com/no-problem-dev/swift-markdown-view.git", from: "1.0.0")
]
```

Add to your target:

```swift
.target(
    name: "YourTarget",
    dependencies: [
        .product(name: "SwiftMarkdownView", package: "swift-markdown-view")
    ]
)
```

## Supported Elements

### Block Elements

| Element | Markdown | Support |
|---------|----------|---------|
| Headings | `# H1` ~ `###### H6` | ✅ |
| Paragraphs | text | ✅ |
| Code Blocks | ` ```swift ``` ` | ✅ |
| Blockquotes | `> quote` | ✅ |
| Unordered Lists | `- item` | ✅ |
| Ordered Lists | `1. item` | ✅ |
| Task Lists | `- [x] done` | ✅ |
| Tables | `\| col \|` | ✅ |
| Thematic Breaks | `---` | ✅ |

### Inline Elements

| Element | Markdown | Support |
|---------|----------|---------|
| Emphasis (italic) | `*text*` | ✅ |
| Strong (bold) | `**text**` | ✅ |
| Inline Code | `` `code` `` | ✅ |
| Links | `[text](url)` | ✅ |
| Images | `![alt](url)` | ✅ |
| Strikethrough | `~~text~~` | ✅ |

### Supported Languages for Syntax Highlighting

| Language | Aliases |
|----------|---------|
| Swift | `swift` |
| TypeScript | `typescript`, `ts`, `tsx` |
| JavaScript | `javascript`, `js`, `jsx` |
| Python | `python`, `py` |
| Go | `go`, `golang` |
| Rust | `rust`, `rs` |
| Java | `java` |
| Kotlin | `kotlin`, `kt` |
| Ruby | `ruby`, `rb` |
| Shell | `shell`, `bash`, `sh`, `zsh` |
| SQL | `sql` |
| HTML | `html`, `htm`, `xml` |
| CSS | `css`, `scss`, `sass`, `less` |
| JSON | `json` |
| YAML | `yaml`, `yml` |

## Advanced Usage

### Custom Syntax Tokenizer

```swift
struct MyTokenizer: SyntaxTokenizer {
    func tokenize(_ code: String, language: String?) -> [SyntaxToken] {
        // Custom implementation
    }
}

MarkdownView("```swift\ncode\n```")
    .syntaxTokenizer(MyTokenizer())
```

### Apply DesignSystem Theme

```swift
MarkdownView("# Themed Markdown")
    .environment(\.colorPalette, .dark)
    .environment(\.typographyScale, .large)
```

## Dependencies

- [swift-markdown](https://github.com/swiftlang/swift-markdown) - Markdown parsing
- [swift-design-system](https://github.com/no-problem-dev/swift-design-system) - Design tokens

## Documentation

Detailed API documentation is available on [GitHub Pages](https://no-problem-dev.github.io/swift-markdown-view/documentation/swiftmarkdownview/).

## License

MIT License - See [LICENSE](LICENSE) for details.
