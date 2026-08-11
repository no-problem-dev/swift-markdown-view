# Changelog

## [Unreleased]

### Fixed

- Code block backgrounds, thematic breaks, table row separators, and block quote bars now follow
  the appearance the document is drawn in. `MarkdownDecorationPalette` turned the theme's colors
  into `CGColor` when it was built, which is in `makeUIView` / `updateUIView`, where the current
  trait collection is not the text view's. A `CGColor` is a concrete color, so a dynamic
  `UIColor` asked for one there resolved light and stayed light: the body text followed the user
  into dark mode and every decoration kept its light color. In the package's own dark-appearance
  snapshots the quote bar, the rules, and the table separators all measured rgb(208,208,210) —
  the same value as in light — while the text beside them measured rgb(243,243,249). An aside's
  tinted bar was already right, because that color is read from the text storage inside
  `draw(at:in:)`; the palette default beside it was not.

  The palette now carries `UIColor` / `NSColor`, and the color becomes a `CGColor` inside the
  drawing call. On iOS the code block background is a `CAShapeLayer` fill, which can only hold a
  concrete color, so it is resolved against the view's own trait collection and repainted when a
  trait that decides how a color resolves changes.

## [6.0.0] - 2026-08-11

### Fixed

- `MarkdownView` now reads `MarkdownRenderingOptions.renderMath`. Until now only `MathText`
  read it, so passing `renderMath: false` still typeset the math in the document.
  Images and Mermaid render as before.
- `MarkdownEditor` no longer overwrites the theme's `baseFontSize`. The font size of the theme
  placed in the environment now takes effect as it is.

### Removed

- Removed `baseFontSize` from the `MarkdownEditor` initializer. `MarkdownEditorTheme` is now
  the one place that decides the body text size.
- Removed `RuleTransform.allowCoalescing`. No rule set it and nothing read it.
- Removed the `.markdownSource` attribute key. It was written in 4 places and had no reader.

### Changed

- Put the toolbar labels, the mode picker display names, and the logs for image, Mermaid, and highlighting failures into English.

## [5.0.0] - 2026-08-10

### Changed

- Bumped the swift-design-system pin to 3.0.0 and the swift-latex-view pin to 0.3.0.
