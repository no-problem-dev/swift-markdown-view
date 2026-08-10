# Module Structure

Which product to add, what each one links, and why the package is split the way it is.

## Overview

The package ships seven library products. Only two of them are entry points you are likely to
import: `SwiftMarkdownView` to render, `SwiftMarkdownEditor` to edit. Everything else is opt-in,
and each add-on exists to keep a dependency out of the core.

### Products

| Product | Role |
|---|---|
| `SwiftMarkdownView` | The renderer, and the entry point for theming. Re-exports the content model and the attributed-string types |
| `SwiftMarkdownEditor` | The editor: source view, formatting toolbar, mode switching, live preview. Re-exports the editor's own model, rules, and TextKit layers |
| `SwiftMarkdownViewHighlightJS` | Syntax highlighting for 50+ languages, via HighlightSwift |
| `SwiftMarkdownViewLaTeX` | LaTeX typesetting for inline and display math, via SwiftLaTeXView |
| `SwiftMarkdownViewDesignSystem` | Maps `swift-design-system` tokens onto the renderer's theming protocols |
| `SwiftMarkdownEditorDesignSystem` | The same bridge for the editor theme |
| `SwiftMarkdownViewCatalog` | Demo screens that render every supported element. Not needed to use the library |

### Layers behind the renderer

The products above sit on internal targets, split by what makes them change rather than by
technical category.

- **Model** parses Markdown into UI-independent block and inline types. It imports Foundation and
  swift-markdown, never SwiftUI or UIKit, so the renderer, the TextKit layer, and the editor can
  all depend on it without inheriting a UI framework.
- **Attributed** composes the model into a single `NSAttributedString`, and owns the semantic
  attribute keys, decoration descriptors, and attachment protocols. Cross-block selection and Copy
  are decided here, which is why this layer is headless and unit-testable.
- **TextKit** wraps that string in one read-only `UITextView` / `NSTextView` with custom layout
  fragment drawing. One text storage for the whole document is what makes a selection run from a
  heading, through a code block, into a table.
- **Platform** holds nothing but the UIKit/AppKit cross-platform aliases. It exists because the
  renderer side and the editor side each used to declare their own `PlatformColor`, which became
  ambiguous in the scope of anyone importing both.

The editor mirrors the same shape: a pure-logic core (document state, text changes, offset
mapping, tokenizer), a rules layer for autoformatting, a TextKit bridge, and the public SwiftUI
layer on top.

### Why the catalog is a separate product

Demo screens change when there is a new feature to show. The renderer changes when the Markdown
handling or the layout is wrong. Keeping them in one target means a change to a demo screen forces
a major version bump on the library.

## Dependencies

| Package | Purpose | When it is linked |
|---|---|---|
| [swift-markdown](https://github.com/swiftlang/swift-markdown) | Markdown parsing | Always |
| [HighlightSwift](https://github.com/appstefan/HighlightSwift) | Syntax highlighting | `SwiftMarkdownViewHighlightJS` only |
| [swift-latex-view](https://github.com/no-problem-dev/swift-latex-view) | LaTeX typesetting, which pulls in [SwiftMath](https://github.com/mgriebling/SwiftMath) | `SwiftMarkdownViewLaTeX` only |
| [swift-design-system](https://github.com/no-problem-dev/swift-design-system) | Design tokens | The two bridge products, the LaTeX product, and the catalog |
| [swift-visual-testing](https://github.com/no-problem-dev/swift-visual-testing) | Snapshot testing | Tests only |
| [swift-docc-plugin](https://github.com/apple/swift-docc-plugin) | Documentation generation | Build tooling only |

`SwiftMarkdownView` and `SwiftMarkdownEditor` do not link `swift-design-system`. SwiftPM still
resolves it, because the optional products in the same package need it, but its types never reach
your code unless you add one of those products yourself.

## Platform support

The package declares iOS 17 and macOS 14 only. tvOS and watchOS are deliberately absent:
`swift-design-system` and `swift-latex-view` declare neither, so the graph could not resolve for
them. Declaring a platform the dependencies cannot support turns a clear "unsupported" into an
unexplained resolution failure.

## Topics

### Getting oriented

- <doc:GettingStarted>
- <doc:SupportedElements>
