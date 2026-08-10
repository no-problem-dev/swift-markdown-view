# Getting Started

Render your first document, then parse ahead of time and adjust the appearance.

## Overview

`MarkdownView` takes a Markdown string and draws it. There is no document type to build and no
configuration step — the string is the input, and the defaults are chosen so that the result is
readable in light and dark mode without any setup.

## Render a document

Wrap it in a `ScrollView` when the content can exceed the screen. The view sizes itself to its
content, so it does not scroll on its own.

```swift
import SwiftUI
import SwiftMarkdownView

struct ReleaseNotesView: View {
    let notes: String

    var body: some View {
        ScrollView {
            MarkdownView(notes)
                .padding(.horizontal)
        }
        .navigationTitle("What's New")
    }
}
```

Everything in <doc:SupportedElements> works from here. Try a document with a table and a task list
in it — the interesting part is that you can drag a selection from the prose, through the table,
and out the other side, and paste something legible.

## Parse ahead of time

`MarkdownView(_:)` parses the string when the view is created. That is the right default, but it
happens on the main actor, and it happens again for every instance that receives the same string.

`MarkdownContent` is the parsed form. Build it once — off the main actor if the document is
large, or once per document rather than once per row in a list — and hand the result to the view.

```swift
// Off the main actor, or once when the document is loaded.
let content = MarkdownContent(parsing: article.body)

// Later, on the main actor.
MarkdownView(content)
```

This matters most in a `List` or `LazyVStack`, where the same content is re-created as cells are
recycled.

## Adjust the appearance

The three theming protocols are separate so that you can override one without restating the
others. Colors live in ``MarkdownPalette``:

```swift
struct DocsPalette: MarkdownPalette {
    var text: Color { .primary }
    var secondaryText: Color { .secondary }
    var heading: Color { .indigo }
    var link: Color { .accentColor }
    var codeBackground: Color { Color.indigo.opacity(0.08) }
    var rule: Color { Color.secondary.opacity(0.3) }
}

MarkdownView(content)
    .markdownPalette(DocsPalette())
```

Spacing and type sizes work the same way through ``MarkdownMetrics`` and ``MarkdownTypeScale``.
See <doc:Theming> for the full picture, including the `swift-design-system` bridge.

## Add the optional pieces

Two capabilities are separate products, so that documents that do not need them do not pay for
them:

- Fenced code blocks render without color until a highlighter is installed. Add the
  `SwiftMarkdownViewHighlightJS` product and call `.adaptiveSyntaxHighlighting()`. See
  <doc:SyntaxHighlighting>.
- Math renders as its own source text until a renderer is installed. Add the
  `SwiftMarkdownViewLaTeX` product and inject `.markdownMathRenderer(LaTeXMathRenderer())`.

## Consider where the Markdown comes from

If the document is not written by your app — model output, user submissions, content fetched from
a server — then the image sources in it are chosen by whoever wrote it. ``MarkdownImagePolicy``
governs what those sources may reach. The default already refuses the file system; tighten it to
`.bundleOnly` when the document should not be able to make network requests either.

```swift
MarkdownView(untrustedSource)
    .markdownImagePolicy(.bundleOnly)
```

## Next steps

- <doc:SupportedElements>
- <doc:Theming>
- <doc:SyntaxHighlighting>
- <doc:Asides>
- <doc:MermaidDiagrams>
- <doc:ModuleStructure>
