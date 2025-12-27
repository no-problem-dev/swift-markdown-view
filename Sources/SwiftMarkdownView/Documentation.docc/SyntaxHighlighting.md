# Syntax Highlighting

Learn how to customize syntax highlighting for code blocks.

## Overview

SwiftMarkdownView includes built-in syntax highlighting for 15 programming languages
using a lightweight regex-based highlighter. You can also use the optional
`SwiftMarkdownViewHighlightJS` module for more accurate highlighting with 50+ languages.

## Supported Languages

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

## Token Types

Syntax highlighting categorizes code into the following token types:

- `keyword`: Language keywords (`func`, `class`, `if`, etc.)
- `string`: String literals
- `number`: Numeric literals
- `comment`: Comments
- `type`: Type names
- `property`: Property names
- `punctuation`: Punctuation and operators
- `plain`: Plain text

## Custom Highlighter

To implement custom syntax highlighting, create a highlighter conforming to
the ``SyntaxHighlighter`` protocol.

```swift
struct MyCustomHighlighter: SyntaxHighlighter {
    func highlight(_ code: String, language: String?) async throws -> AttributedString {
        // Custom implementation
        var result = AttributedString(code)
        // Apply highlighting
        return result
    }
}
```

### Applying a Custom Highlighter

```swift
MarkdownView("```swift\nlet x = 1\n```")
    .syntaxHighlighter(MyCustomHighlighter())
```

## Using HighlightJS (Recommended for Accuracy)

For more accurate syntax highlighting with 50+ language support, use the
`SwiftMarkdownViewHighlightJS` module:

```swift
import SwiftMarkdownViewHighlightJS

MarkdownView(source)
    .syntaxHighlighter(HighlightJSSyntaxHighlighter(theme: .xcode, colorMode: .dark))
```

### Available Presets

```swift
// Xcode themes
HighlightJSSyntaxHighlighter.xcodeLight
HighlightJSSyntaxHighlighter.xcodeDark

// GitHub themes
HighlightJSSyntaxHighlighter.githubLight
HighlightJSSyntaxHighlighter.githubDark

// Atom One themes
HighlightJSSyntaxHighlighter.atomOneLight
HighlightJSSyntaxHighlighter.atomOneDark
```

## Color Customization

Use ``SyntaxColorScheme`` to customize the highlighting colors for the built-in
regex highlighter:

```swift
let customColors = SyntaxColorScheme(
    keyword: .purple,
    string: .orange,
    comment: .gray,
    number: .blue,
    type: .teal,
    property: .cyan,
    punctuation: .secondary,
    plain: .primary
)

let highlighter = RegexSyntaxHighlighter(colors: customColors)
MarkdownView(source)
    .syntaxHighlighter(highlighter)
```
