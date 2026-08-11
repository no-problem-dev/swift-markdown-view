# Changelog

## [Unreleased]

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
