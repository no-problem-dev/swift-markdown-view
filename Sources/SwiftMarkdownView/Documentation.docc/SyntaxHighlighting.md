# Syntax Highlighting

Color fenced code blocks, with the bundled highlighter or one of your own.

## Overview

Out of the box, code blocks render in a monospaced font with no coloring. ``PlainTextHighlighter``
is the default, and it is a deliberate one: a highlighter is a real dependency, and a document
whose code blocks are shell transcripts or configuration snippets gains little from it.

When your Markdown does contain source code, add the `SwiftMarkdownViewHighlightJS` product. It
wraps HighlightSwift and covers 50+ languages.

```swift
import SwiftMarkdownViewHighlightJS

MarkdownView(source)
    .adaptiveSyntaxHighlighting()
```

`adaptiveSyntaxHighlighting()` follows the environment's color scheme, switching between the light
and dark variant of a theme as the system does. It defaults to the `a11y` theme, which is tuned
for contrast — the safe choice when you do not know how your readers have configured their
displays.

## Choose a theme

Pass a theme to keep the automatic light/dark switching but change the palette:

```swift
MarkdownView(source)
    .adaptiveSyntaxHighlighting(theme: .github)
```

| Theme | Notes |
|---|---|
| `.a11y` | Contrast-optimised. The default |
| `.xcode` | Matches Xcode's own coloring |
| `.github` | Matches rendered GitHub |
| `.atomOne` | |
| `.solarized` | |
| `.tokyoNight` | Only a dark preset is provided |

To pin one appearance regardless of the system setting — a document rendered for print or export,
say — construct the highlighter directly:

```swift
MarkdownView(source)
    .markdownSyntaxHighlighter(
        HighlightJSSyntaxHighlighter(theme: .atomOne, colorMode: .dark)
    )
```

The paired presets are shorthand for exactly that: `.xcodeLight`, `.xcodeDark`, `.githubLight`,
`.githubDark`, `.atomOneLight`, `.atomOneDark`, `.solarizedLight`, `.solarizedDark`, `.a11yLight`,
`.a11yDark`, and `.tokyoNightDark`.

## Apply it once for the whole app

The highlighter travels through the environment, so one call high in the hierarchy covers every
`MarkdownView` below it — including the ones inside `MarkdownEditor`'s preview pane.

```swift
@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .adaptiveSyntaxHighlighting()
        }
    }
}
```

## Write your own highlighter

``SyntaxHighlighter`` is a single async method, so a highlighter can call out to whatever engine
you like without blocking rendering. Return an `AttributedString` carrying the attributes you
want; the renderer keeps them and supplies the font and background itself.

```swift
struct KeywordHighlighter: SyntaxHighlighter {
    func highlight(_ code: String, language: String?) async throws -> AttributedString {
        guard language == "swift" else { return AttributedString(code) }
        var result = AttributedString(code)
        // Apply your own attributes here.
        return result
    }
}

MarkdownView(source)
    .markdownSyntaxHighlighter(KeywordHighlighter())
```

`language` is the fence's info string, or `nil` for an untagged fence. Return the input unchanged
for a language you do not handle. Highlighting is never allowed to blank the screen: while the
work is in flight, and again if it throws, the code is shown as unstyled text.

## Turn it off again

Applying ``PlainTextHighlighter`` explicitly removes highlighting for one subtree without undoing
the app-wide setting:

```swift
MarkdownView(untrustedSource)
    .markdownSyntaxHighlighter(PlainTextHighlighter())
```

## Topics

### Protocol and defaults

- ``SyntaxHighlighter``
- ``PlainTextHighlighter``
- ``HighlightState``

### Code block view

- ``HighlightedCodeView``
