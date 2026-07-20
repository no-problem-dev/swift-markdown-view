// エディタは 4 ターゲットに分かれている（純ロジックの Core、オートフォーマットの Rules、
// TextKit 2 ブリッジの TextKit、そしてこの SwiftUI 層）。分割の理由は変更理由の違いで、
// 利用者に 4 つの import を書かせるためではない。
//
// `MarkdownEditor.init` は `InputRuleProcessor`（Rules）を引数に取り、
// `.markdownEditorTheme(_:)` は `MarkdownEditorTheme`（TextKit）を取り、
// 独自コマンドは `EditTransform` / `MarkdownFormatting`（Core）で組み立てる。
// つまり公開シグネチャが 3 ターゲットに跨っているので、名前をここへ集約する。
//
// 契約でないもの（LineIndex / InlineSpan / InlineSpanParser / StyleRun /
// LivePreviewStyler / 各 Representable の実装詳細）は package に落としてあるので、
// この再輸出から漏れることはない。
@_exported import SwiftMarkdownEditorCore
@_exported import SwiftMarkdownEditorRules
@_exported import SwiftMarkdownEditorTextKit
