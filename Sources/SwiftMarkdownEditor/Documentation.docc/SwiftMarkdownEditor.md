# ``SwiftMarkdownEditor``

ライブシンタックスハイライト・フォーマットツールバー・レンダリングプレビューを備えた SwiftUI Markdown エディタ。

@Metadata {
    @PageColor(orange)
}

## Overview

`SwiftMarkdownEditor` は `MarkdownEditor` を提供する。プラットフォーム標準のテキストビューをラップしてソース編集を行い、レンダリングプレビューには `MarkdownView` を再利用するドロップイン SwiftUI `View`。バインドされたプレーン Markdown 文字列が唯一の正であり、中間表現は公開しない。

`MarkdownEditorMode` で制御する 3 つの表示モードをサポートする。`.edit` モードではライブシンタックスハイライトを適用してソースを表示する（iOS は TextKit 2、macOS は TextKit 1。ハイライトは属性の付与だけなので挙動は同じ）。`.preview` モードではレンダリングされた `MarkdownView` がコンテンツ領域を占める。`.split` モード（macOS や幅広 iPad レイアウトに最適）では両パネルがディバイダーで区切られて並列表示される。ユーザーはエディタヘッダーのセグメントコントロールでモードを切り替える。

`.edit` モードと `.split` モードでは、モードスイッチャーの下にスクロール可能なフォーマットツールバーが表示される。各ボタンは太字・斜体・取り消し線・インラインコード・見出し変換・箇条書き・引用・リンク挿入などのフォーマット変換をソーステキストビューの選択範囲に適用する。

オートフォーマット入力ルールはユーザーのタイプに応じて自動的に発火する。デフォルトのルールセットは Return でリストアイテムを継続し、選択テキストを対応する Markdown デリミタで囲む。ルールを拡張・置換するにはカスタムの `InputRuleProcessor` をイニシャライザに渡す。

```swift
import SwiftUI
import SwiftMarkdownEditor

struct NoteEditor: View {
    @State private var source = "# My Note\n\nStart writing…"

    var body: some View {
        MarkdownEditor(text: $source)
    }
}
```

色とスペーシングは SwiftUI 環境内の `swift-design-system` テーマから取得するため、アプリ全体のデザインに自動的に合わせる。

## Topics

### エディタビュー

- ``MarkdownEditor``
- ``MarkdownEditorMode``
