# Supported Elements

The Markdown syntax the renderer understands, and what it turns each construct into.

## Overview

The parser accepts CommonMark plus the GitHub Flavored Markdown extensions for tables, task
lists, and strikethrough, and adds three constructs of its own: aside callouts, Mermaid diagrams,
and math.

Anything the renderer does not recognise falls through as text rather than disappearing, so an
unsupported construct degrades to something readable instead of a blank region.

## Block elements

| Element | Markdown | Notes |
|---|---|---|
| Headings | `# H1` through `###### H6` | Sized from the type scale, so six levels stay distinguishable |
| Paragraphs | plain text | Spacing comes from the metrics |
| Code blocks | ` ```swift ` | Highlighted only if a highlighter is installed. See <doc:SyntaxHighlighting> |
| Asides | `> Note: text` | 24 recognised kinds plus custom. See <doc:Asides> |
| Mermaid | ` ```mermaid ` | Drawn by Mermaid.js in a web view, once a script provider can supply it. See <doc:MermaidDiagrams> |
| Math | `$$…$$` or ` ```math ` | Display math. Typeset only with the LaTeX product installed |
| Unordered lists | `- item` | Nesting supported |
| Ordered lists | `1. item` | Nesting supported |
| Task lists | `- [x] done` | Checkboxes render as glyphs, not controls |
| Tables | `\| col \|` | Per-column alignment honoured |
| Thematic breaks | `---` | |

## Inline elements

| Element | Markdown |
|---|---|
| Emphasis | `*text*` |
| Strong | `**text**` |
| Inline code | Text between backticks |
| Links | `[text](url)` |
| Images | `![alt](url)` |
| Strikethrough | `~~text~~` |
| Inline math | `$…$` or `\(…\)` |

## How elements reach the screen

Every block above becomes runs in one attributed string, and that string backs one text view.
That is what lets a selection start in a heading and end inside a table, and what makes Copy
produce text a person can read rather than a slice of layout.

Elements that cannot be expressed as text runs — images, display math, Mermaid diagrams — become
attachments sized to the available width and rasterised at device resolution, so they stay sharp
and stay inside the same selection.
