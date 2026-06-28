# ``SwiftMarkdownViewLaTeX``

LaTeX math typesetting for `SwiftMarkdownView`, powered by SwiftLaTeXView.

@Metadata {
    @PageColor(purple)
}

## Overview

`SwiftMarkdownViewLaTeX` is an optional add-on for `SwiftMarkdownView` that upgrades math expressions from plain source display to proper LaTeX typesetting. It provides `LaTeXMathRenderer`, a `MathRenderer` implementation that delegates rendering to SwiftLaTeXView — a lightweight wrapper around the SwiftMath engine that renders LaTeX directly into Core Text glyphs without a WebView.

Both inline math (`$...$`) and display math (`$$...$$`) in Markdown source are supported. Inline expressions flow inside the surrounding `Text` run; display math renders as a full-width block view. In the TextKit 2 path used by `MarkdownView`, display math is rasterised as a device-scale image attachment so it renders crisply inside the continuous text view.

To enable math typesetting, add `SwiftMarkdownViewLaTeX` to your target's dependencies and inject the renderer into the view hierarchy:

```swift
import SwiftMarkdownView
import SwiftMarkdownViewLaTeX

MarkdownView("""
The quadratic formula: $ax^2 + bx + c = 0$

$$x = \\frac{-b \\pm \\sqrt{b^2 - 4ac}}{2a}$$
""")
.mathRenderer(LaTeXMathRenderer())
```

The renderer's visual style — font family, font sizes, and text colour — derives from the `swift-design-system` theme in the SwiftUI environment. Pass a custom `MathStyle` to the initialiser when you need to override the defaults.

## Topics

### Math Renderer

- ``LaTeXMathRenderer``
