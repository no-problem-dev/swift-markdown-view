# ``SwiftMarkdownViewHighlightJS``

Syntax highlighting for 50+ languages in rendered Markdown code blocks.

@Metadata {
    @PageColor(green)
}

## Overview

`SwiftMarkdownView` renders fenced code blocks without color on its own. This module supplies the
coloring, wrapping [HighlightSwift](https://github.com/appstefan/HighlightSwift) behind the
renderer's `SyntaxHighlighter` protocol.

It is a separate product so that the core carries no highlighting dependency. Add it when your
documents actually contain source code.

```swift
import SwiftMarkdownView
import SwiftMarkdownViewHighlightJS

MarkdownView(source)
    .adaptiveSyntaxHighlighting()
```

`adaptiveSyntaxHighlighting()` tracks the environment's color scheme, so the palette follows the
system between light and dark. It defaults to the `a11y` theme, which is tuned for contrast — the
right default when you cannot know how a reader has set up their display.

To pin one appearance regardless of the system setting, construct
``HighlightJSSyntaxHighlighter`` with an explicit `colorMode`, or use one of the paired presets
below. Full guidance, including how to write a highlighter of your own, is in the core module's
syntax highlighting article.

## Topics

### Highlighter

- ``HighlightJSSyntaxHighlighter``
- ``HighlightJSSyntaxHighlighter/ColorMode``

### Applying it

- ``SwiftUICore/View/adaptiveSyntaxHighlighting(theme:)``

### Contrast-optimised presets

- ``HighlightJSSyntaxHighlighter/a11yLight``
- ``HighlightJSSyntaxHighlighter/a11yDark``

### Editor-like presets

- ``HighlightJSSyntaxHighlighter/xcodeLight``
- ``HighlightJSSyntaxHighlighter/xcodeDark``
- ``HighlightJSSyntaxHighlighter/atomOneLight``
- ``HighlightJSSyntaxHighlighter/atomOneDark``
- ``HighlightJSSyntaxHighlighter/solarizedLight``
- ``HighlightJSSyntaxHighlighter/solarizedDark``
- ``HighlightJSSyntaxHighlighter/tokyoNightDark``

### Web-like presets

- ``HighlightJSSyntaxHighlighter/githubLight``
- ``HighlightJSSyntaxHighlighter/githubDark``
