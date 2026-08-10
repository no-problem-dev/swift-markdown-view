// The semantic model (MarkdownContent / MarkdownBlock / MarkdownInline / the table and list
// types) lives in the UI-independent `MarkdownModel` target, shared alike by the SwiftUI
// renderer, the TextKit renderer, and the editor. They are first-class domain types, so
// re-export them and `import SwiftMarkdownView` on its own keeps working as before.
@_exported import MarkdownModel

// The TextKit rendering layer. This re-export used to spill the whole implementation into client
// scope — builders, code regions, image requests, block decorations, attribute keys. Those are
// `package` now, so all that comes through here are the four types a client actually touches:
//
//   - MarkdownTextTheme          … resolved fonts, colors, and spacing
//   - MarkdownAttachment         … an image / math / Mermaid run, and its `Kind`
//   - MarkdownRenderedImage      … an attachment image plus its baseline offset
//   - MarkdownAttachmentRendering… what a custom attachment renderer conforms to
//
// Every one of them appears in the signature of `MarkdownAttachmentRendering`, so the names have
// to reach anyone writing a renderer of their own.
@_exported import MarkdownAttributedKit
