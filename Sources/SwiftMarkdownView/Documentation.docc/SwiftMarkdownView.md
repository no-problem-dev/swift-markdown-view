# ``SwiftMarkdownView``

SwiftUI ネイティブな Markdown レンダリング・編集ライブラリ。

@Metadata {
    @PageColor(blue)
}

## Overview

`SwiftMarkdownView` は Markdown テキストをネイティブ SwiftUI ビューとしてレンダリングする。CommonMark と GitHub Flavored Markdown をサポートし、テーブル・タスクリスト・Aside コールアウト・Mermaid ダイアグラム・数式に対応する。iOS と macOS では単一の TextKit 2 テキストビューを使用するため、ブロック境界をまたいだ選択とコピーが連続して機能する。

ライブラリはデフォルトで `swift-design-system` と統合されており、タイポグラフィトークン・カラーパレット・スペーシングスケールがすべて SwiftUI 環境を通じて流れるため、Markdown がアプリの残りのビジュアル言語に自動的に一致する。

`SwiftMarkdownView` は 4 モジュール構成のコアモジュール。必要なプロダクトだけをインポートすればよく、各アドオンは他モジュールへの必須依存なしの独立したライブラリプロダクトだ。

```swift
import SwiftUI
import SwiftMarkdownView

struct ArticleView: View {
    let markdown: String

    var body: some View {
        ScrollView {
            MarkdownView(markdown)
                .padding()
        }
    }
}
```

`SwiftMarkdownViewHighlightJS` は HighlightSwift を使用した 50 以上のプログラミング言語に対応する高精度シンタックスハイライトを追加する。Xcode・GitHub・Atom One・Solarized・Tokyo Night・アクセシブルな `a11y` シリーズなど豊富なライト/ダークテーマを内蔵し、`.adaptiveSyntaxHighlighting()` でシステムのカラースキームと自動連動する。Markdown にコードブロックが含まれる可能性があり、プレーンな等幅出力では不十分な場合にインポートする。

`SwiftMarkdownViewLaTeX` はインライン `$...$` とブロック `$$...$$` の数式をプレーンなソーステキストから SwiftMath エンジンによる本格的な LaTeX 組版にアップグレードする。インライン数式は周囲の `Text` 行内に自然にフローし、ディスプレイ数式は全幅ブロックとしてレンダリングされる。ビュー階層に `.mathRenderer(LaTeXMathRenderer())` を注入することで有効化する。Markdown に数式表記が含まれる可能性がある場合にインポートする。

`SwiftMarkdownEditor` は完全な Markdown 執筆体験を提供する。`MarkdownEditor` はリアルタイムシンタックスハイライト・スクロール可能なフォーマットツールバー・内部で `MarkdownView` を再利用するオプションのサイドバイサイドプレビューペインを備えた TextKit 2 ソースエディタをラップする。プレーンな Markdown 文字列が常に唯一の信頼できる情報源となる。レンダリングに加えて執筆機能を追加する場合にインポートする。

モジュール構成:

```
SwiftMarkdownView (core renderer — this module)
  ├── SwiftMarkdownViewHighlightJS  → HighlightJSSyntaxHighlighter, .adaptiveSyntaxHighlighting()
  ├── SwiftMarkdownViewLaTeX        → LaTeXMathRenderer
  └── SwiftMarkdownEditor           → MarkdownEditor, MarkdownEditorMode
```

```swift
import SwiftUI
import SwiftMarkdownView

struct ArticleView: View {
    let markdown: String

    var body: some View {
        ScrollView {
            MarkdownView(markdown)
                .padding()
        }
    }
}
```

## Topics

### はじめに

- <doc:GettingStarted>

### ビュー

- ``MarkdownView``
- ``HighlightedCodeView``

### コンテンツモデル

- ``MarkdownContent``
- ``MarkdownBlock``
- ``MarkdownInline``

### シンタックスハイライト

- ``SyntaxHighlighter``
- ``PlainTextHighlighter``
- ``HighlightState``
- <doc:SyntaxHighlighting>

### Aside コールアウト

- ``AsideKind``
- <doc:Asides>

### テーマ

- ``MarkdownPalette``
- ``DefaultMarkdownPalette``
- ``MarkdownMetrics``
- ``DefaultMarkdownMetrics``
- ``MarkdownTypeScale``
- ``DefaultMarkdownTypeScale``

### レンダリングオプション

- ``MarkdownRenderingOptions``

### 数式

- ``MathRenderer``
- ``PlainMathRenderer``

### Mermaid ダイアグラム

- ``MermaidScriptProvider``
- ``MermaidScriptSource``
- ``CDNMermaidScriptProvider``
- ``BundledMermaidScriptProvider``
- <doc:MermaidDiagrams>

### ドメイン型

- ``TableData``
- ``ListItem``
