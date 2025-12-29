# Syntax Highlighting

Learn how to customize syntax highlighting for code blocks.

## Overview

SwiftMarkdownView uses ``PlainTextHighlighter`` by default, which applies no coloring.
For full syntax highlighting with 50+ languages, use the optional
`SwiftMarkdownViewHighlightJS` module.

## Quick Start

To enable syntax highlighting:

```swift
import SwiftMarkdownViewHighlightJS

MarkdownView(source)
    .adaptiveSyntaxHighlighting()
```

This automatically adapts to light/dark mode with the a11y theme for accessibility.

## Using HighlightJS

The `SwiftMarkdownViewHighlightJS` module provides accurate highlighting for 50+ languages:

```swift
import SwiftMarkdownViewHighlightJS

// Adaptive highlighting (recommended)
MarkdownView(source)
    .adaptiveSyntaxHighlighting()

// With specific theme
MarkdownView(source)
    .adaptiveSyntaxHighlighting(theme: .github)

// Manual configuration
MarkdownView(source)
    .syntaxHighlighter(
        HighlightJSSyntaxHighlighter(theme: .atomOne, colorMode: .dark)
    )
```

### Available Themes

| Theme | Description |
|-------|-------------|
| `.a11y` | Accessibility-optimized (recommended) |
| `.xcode` | Xcode default style |
| `.github` | GitHub style |
| `.atomOne` | Atom One style |
| `.solarized` | Solarized style |
| `.tokyoNight` | Tokyo Night style |

### Theme Presets

```swift
HighlightJSSyntaxHighlighter.xcodeLight
HighlightJSSyntaxHighlighter.xcodeDark
HighlightJSSyntaxHighlighter.githubLight
HighlightJSSyntaxHighlighter.githubDark
HighlightJSSyntaxHighlighter.atomOneLight
HighlightJSSyntaxHighlighter.atomOneDark
HighlightJSSyntaxHighlighter.a11yLight
HighlightJSSyntaxHighlighter.a11yDark
```

## Custom Highlighter

To implement custom syntax highlighting, create a highlighter conforming to
the ``SyntaxHighlighter`` protocol:

```swift
struct MyCustomHighlighter: SyntaxHighlighter {
    func highlight(_ code: String, language: String?) async throws -> AttributedString {
        var result = AttributedString(code)
        // Apply custom highlighting
        return result
    }
}

MarkdownView(source)
    .syntaxHighlighter(MyCustomHighlighter())
```

## Disabling Syntax Highlighting

By default, no syntax highlighting is applied. To explicitly use plain text:

```swift
// Default behavior - no highlighting
MarkdownView(source)

// Explicit plain text highlighter
MarkdownView(source)
    .syntaxHighlighter(PlainTextHighlighter())
```

## App-Wide Configuration

Apply syntax highlighting to your entire app:

```swift
import SwiftMarkdownViewHighlightJS

@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .theme(ThemeProvider())
                .adaptiveSyntaxHighlighting()
        }
    }
}
```

## Catalog Usage

To enable syntax highlighting in the Markdown catalog:

```swift
import SwiftMarkdownViewHighlightJS

MarkdownCatalogView()
    .theme(ThemeProvider())
    .adaptiveSyntaxHighlighting()
```
