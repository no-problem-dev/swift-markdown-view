# Asides

Turn a block quote into a labelled callout for notes, warnings, and tips.

## Overview

A block quote that names a kind is drawn as a callout: a colored, bold label above the content,
with a colored bar down the side. A block quote that names no kind stays an ordinary quote, so
adding callouts to a document does not relabel the quotations already in it.

Two spellings are recognised. The DocC style puts the kind before a colon:

```swift
MarkdownView("""
> Note: Supplementary information.

> Warning: This needs attention.

> Tip: A useful shortcut.
""")
```

The GitHub style uses a bracketed marker, which is stripped from the text that gets displayed:

```swift
MarkdownView("""
> [!WARNING]
> This needs attention.
""")
```

Matching ignores case, so `> note:`, `> Note:`, and `> [!NOTE]` all arrive at the same kind.

## Kinds

Twenty-four kinds are recognised. The five in the first group are the ones most documents reach
for; the rest come from DocC's vocabulary and are useful when the Markdown is itself API
documentation.

| Common | Documentation |
|---|---|
| `Note`, `Tip`, `Important`, `Warning`, `Experiment` | `Attention`, `Author`, `Authors`, `Bug`, `Complexity`, `Copyright`, `Date`, `Invariant`, `MutatingVariant`, `NonMutatingVariant`, `Postcondition`, `Precondition`, `Remark`, `Requires`, `Since`, `ToDo`, `Version`, `Throws`, `SeeAlso` |

Any other tag becomes `AsideKind`, carrying the tag text exactly as written. It is
displayed as its own label rather than being discarded:

```swift
MarkdownView("> Migration: Run the schema step before deploying.")
```

## Color

The label and the bar are tinted by kind, from the system palette so that the tint adapts to
light and dark on its own:

| Tint | Kinds |
|---|---|
| Green | `Tip`, `Experiment` |
| Orange | `Important`, `Attention` |
| Red | `Warning`, `Bug` |
| Purple | `ToDo` |
| Blue | Everything else |

A custom kind named `caution`, `warning`, `tip`, or `important` picks up the matching tint; any
other custom kind uses the theme's secondary color, so an unrecognised tag reads as neutral rather
than borrowing a meaning it was not given.

## Content

An aside holds whole blocks, not just a line of text. Lists, code blocks, and multiple paragraphs
all nest inside one:

```swift
MarkdownView("""
> Warning: Before deploying to production
>
> Check each of these:
>
> - Environment variables are set
> - The database connection is reachable
> - The log level is not left on debug
>
> ```swift
> let config = Config.production
> ```
""")
```

Because the callout is composed into the same text storage as the rest of the document, a
selection can run from the prose above it, through the aside, and out the other side.
