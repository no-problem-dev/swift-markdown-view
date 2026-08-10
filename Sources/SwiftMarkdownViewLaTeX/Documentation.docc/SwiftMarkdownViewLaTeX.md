# ``SwiftMarkdownViewLaTeX``

LaTeX typesetting for the math in a rendered Markdown document.

@Metadata {
    @PageColor(purple)
}

## Overview

Without a math renderer installed, `SwiftMarkdownView` shows math as the source you wrote. This
module upgrades it to typeset output, supplying ``LaTeXMathRenderer`` — a `MathRenderer` backed by
SwiftLaTeXView, which draws LaTeX straight to Core Text glyphs through the SwiftMath engine rather
than going through a web view.

Both forms are handled. Inline math (`$…$`) flows within the surrounding line of text, and display
math (`$$…$$`) becomes a full-width block. In the TextKit 2 path that `MarkdownView` uses, display
math is rasterised at device resolution as an attachment, so it stays sharp and stays inside the
document's selection rather than interrupting it.

Add the product to your target and inject the renderer into the view hierarchy:

```swift
import SwiftMarkdownView
import SwiftMarkdownViewLaTeX

MarkdownView("""
The quadratic formula: $ax^2 + bx + c = 0$

$$x = \\frac{-b \\pm \\sqrt{b^2 - 4ac}}{2a}$$
""")
.markdownMathRenderer(LaTeXMathRenderer())
```

The renderer takes its font family, size, and text color from the `swift-design-system` theme in
the SwiftUI environment, so equations match the prose around them. Pass a custom `MathStyle` to
the initializer to override that.

This is the one add-on that cannot avoid `swift-design-system`: SwiftLaTeXView's `MathStyle`
protocol requires its color palette and spacing scale. The core renderer stays free of it, so the
dependency arrives only if you opt into math.

## Topics

### Math renderer

- ``LaTeXMathRenderer``
