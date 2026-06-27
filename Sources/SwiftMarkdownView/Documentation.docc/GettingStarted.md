# Getting Started

Learn the basics of rendering Markdown with `SwiftMarkdownView`.

## Overview

`SwiftMarkdownView` lets you drop Markdown rendering into any SwiftUI app with a single import. The library parses CommonMark and GitHub Flavored Markdown and renders it as native SwiftUI — headings, code blocks, tables, task lists, asides, images, and more — while automatically picking up your `swift-design-system` theme.

## Installation

### Swift Package Manager

Add the dependency to your `Package.swift`:

```swift
dependencies: [
    .package(
        url: "https://github.com/no-problem-dev/swift-markdown-view.git",
        .upToNextMajor(from: "1.4.0")
    )
]
```

Then add the product to your target:

```swift
.target(
    name: "YourTarget",
    dependencies: [
        .product(name: "SwiftMarkdownView", package: "swift-markdown-view")
    ]
)
```

To enable syntax highlighting, also add `SwiftMarkdownViewHighlightJS`:

```swift
.product(name: "SwiftMarkdownViewHighlightJS", package: "swift-markdown-view")
```

## Basic Usage

### Rendering a string

Pass a Markdown string directly to ``MarkdownView``:

```swift
import SwiftUI
import SwiftMarkdownView

struct ContentView: View {
    var body: some View {
        ScrollView {
            MarkdownView("""
            # Hello, Markdown!

            This is **bold**, *italic*, and `inline code`.

            ## Lists

            - Item one
            - Item two
            - [x] Completed task

            ```swift
            let message = "Hello, World!"
            print(message)
            ```
            """)
            .padding()
        }
    }
}
```

### Pre-parsing for performance

When you display the same Markdown in multiple places — or parse it off the main thread — use ``MarkdownContent`` directly:

```swift
let content = MarkdownContent(parsing: longMarkdownString)

// Later, on the main thread:
MarkdownView(content)
```

### Applying styles

Use environment modifiers to control how elements appear:

```swift
MarkdownView(source)
    .codeBlockStyle(TerminalCodeBlockStyle())
    .headingStyle(ColoredHeadingStyle())
    .markdownLinkStyle(ClassicLinkStyle())
    .markdownTableStyle(StripedTableStyle())
```

### Enabling syntax highlighting

Add `SwiftMarkdownViewHighlightJS` to your target (see Installation above), then:

```swift
import SwiftMarkdownViewHighlightJS

MarkdownView(source)
    .adaptiveSyntaxHighlighting()   // automatic light/dark theme
```

## Next Steps

- <doc:SyntaxHighlighting>
- <doc:Asides>
- <doc:MermaidDiagrams>
