// The editor lives in four targets (pure logic in Core, autoformatting in Rules,
// the TextKit 2 bridge in TextKit, and this SwiftUI layer). They are split because
// they change for different reasons, not to make callers write four imports.
//
// The public signatures span three of them: `MarkdownEditor.init` takes an
// `InputRuleProcessor` (Rules), `.markdownEditorTheme(_:)` takes a
// `MarkdownEditorTheme` (TextKit), and custom commands are built out of
// `EditTransform` / `MarkdownFormatting` (Core). So the names are gathered here.
//
// Everything that is not part of the contract (LineIndex, InlineSpan,
// InlineSpanParser, StyleRun, LivePreviewStyler, and the representables'
// implementation details) is declared `package`, so it cannot leak out through
// this re-export.
@_exported import SwiftMarkdownEditorCore
@_exported import SwiftMarkdownEditorRules
@_exported import SwiftMarkdownEditorTextKit
