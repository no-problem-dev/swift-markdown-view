# Theming

Match rendered Markdown to your app's colors, spacing, and type sizes.

## Overview

Appearance is described by three protocols, not by one theme object. They are separate because
they change for different reasons — you usually want your brand's link color without also
restating every heading size — and each has a default you inherit until you override it.

| Protocol | Controls | Default |
|---|---|---|
| ``MarkdownPalette`` | Body and secondary text, headings, links, code-block background, thematic rules | System semantic colors |
| ``MarkdownMetrics`` | Paragraph spacing and the indent step for each nesting level | 16 pt and 32 pt |
| ``MarkdownTypeScale`` | Body point size and the six heading sizes | 17 pt body, 32 pt down to 17 pt headings |

Because the defaults are built from system semantic colors, text is legible in light and dark
appearance before you configure anything. Overriding a protocol means taking responsibility for
both appearances yourself — use adaptive colors rather than literal ones.

## Override colors

Implement ``MarkdownPalette`` and apply it to any part of the view hierarchy. It flows through the
environment, so a single call at the top of a screen covers every `MarkdownView` beneath it.

```swift
struct DocsPalette: MarkdownPalette {
    var text: Color { .primary }
    var secondaryText: Color { .secondary }
    var heading: Color { .indigo }
    var link: Color { .accentColor }
    var codeBackground: Color { Color.indigo.opacity(0.08) }
    var rule: Color { Color.secondary.opacity(0.3) }
}

NavigationStack { ArticleList() }
    .markdownPalette(DocsPalette())
```

`heading` is a separate role from `text` so that a document can use a tinted heading without
tinting its prose. `secondaryText` is what table headers and aside bodies fall back to.

## Override spacing and sizes

``MarkdownMetrics`` has two values, and both are load-bearing for how a document reads at a
glance: `paragraphSpacing` sets the rhythm between blocks, and `indentStep` is applied once per
nesting level, so it decides whether a three-level list is still followable.

``MarkdownTypeScale`` supplies `bodySize` and `headingSizes`. Provide six heading sizes, largest
first, matching `# ` through `###### `.

```swift
struct CompactTypeScale: MarkdownTypeScale {
    var bodySize: CGFloat { 15 }
    var headingSizes: [CGFloat] { [26, 22, 19, 17, 16, 15] }
}

MarkdownView(content)
    .markdownTypeScale(CompactTypeScale())
    .markdownMetrics(TightMetrics())
```

## Bridge to swift-design-system

If your app already themes itself with `swift-design-system`, add the
`SwiftMarkdownViewDesignSystem` product instead of implementing the protocols by hand. It reads
the design system's color palette and spacing scale from the environment and maps them onto the
three Markdown protocols, so Markdown follows the app theme — including a theme change at
runtime.

```swift
import DesignSystem
import SwiftMarkdownView
import SwiftMarkdownViewDesignSystem

ContentView()
    .markdownTheme(themeProvider)
```

`markdownTheme(_:)` installs the design system theme and the bridge together. If you already apply
`.theme(_:)` yourself, call `.markdownDesignSystemTokens()` on its own instead — applying the
theme twice is redundant, not harmful, but the narrower call says what you mean.

The bridge is a separate product on purpose: `SwiftMarkdownView` does not link
`swift-design-system`, so its types never appear in your code unless you ask for them. See
<doc:ModuleStructure>.

## Code blocks and math

Neither the palette nor the type scale colors the *inside* of a fenced code block — that is the
highlighter's job, and it has its own themes. See <doc:SyntaxHighlighting>. `codeBackground` is
the surface behind the code, which is why it is on the palette and not on the highlighter.

Math is likewise typeset by its renderer, which derives its font and color from the resolved theme
so that equations match the surrounding text rather than the renderer's own defaults.

## Topics

### Protocols

- ``MarkdownPalette``
- ``MarkdownMetrics``
- ``MarkdownTypeScale``

### Defaults

- ``DefaultMarkdownPalette``
- ``DefaultMarkdownMetrics``
- ``DefaultMarkdownTypeScale``
