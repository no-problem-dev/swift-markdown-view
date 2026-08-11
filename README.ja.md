# SwiftMarkdownView

[English](./README.md) | 日本語

**iOS と macOS の両方で動く Markdown ライブ編集**と、その土台のレンダラ。

`MarkdownEditor` はライブシンタックスハイライト・差し替え可能なフォーマットツールバー・
入力ルール・macOS の分割プレビューを備えた SwiftUI エディタ。`MarkdownView` はドキュメント
全体を 1 つの TextKit 2 テキストビューに描画するため、ブロックを跨いで選択でき、コピーすると
読めるテキストが得られる。

![Swift 6.2+](https://img.shields.io/badge/Swift-6.2+-orange.svg)
![iOS 17+](https://img.shields.io/badge/iOS-17+-blue.svg)
![macOS 14+](https://img.shields.io/badge/macOS-14+-purple.svg)
![License](https://img.shields.io/badge/License-MIT-green.svg)

| 編集中（ライト） | プレビュー（ダーク） |
|---|---|
| <img src=".github/assets/editor-light.png" width="320" alt="編集モードの MarkdownEditor: フォーマットツールバーとソースのライブハイライト"> | <img src=".github/assets/preview-dark.png" width="320" alt="ダークモードで描画した Markdown: 見出し・強調・リスト・タスク・引用・コードブロック・リンク"> |

## 特徴

- **両 OS で動くエディタ**: iOS と macOS で同じ `MarkdownEditor`。macOS 側は互換のための
  張りぼてではなく `NSTextView` の完全実装
- **ブロックを跨ぐ選択**: ドキュメント全体を 1 つのテキストビューに描画するため、見出しから
  コードブロックを通ってテーブルまでドラッグしても、読めるテキストとしてコピーできる
- **入力中のライブプレビュー**: インラインマーカーを隠してその場で描画する（Notion 風）。
  キャレットのある行だけはマーカーが残るので、そこは編集できる。プレーンな Markdown 文字列が
  唯一の正であることは変わらない
- **編集をカスタマイズできる**: ツールバーを項目配列で組む、コントローラを注入して自前の UI
  から操作する、独自の入力ルールを足す
- **豊富な要素**: テーブル、タスクリスト、画像、Mermaid ダイアグラム、LaTeX 数式、24 種類の
  Aside コールアウト
- **デザインシステムに縛られない**: 色・寸法・文字サイズは自分で実装するただのプロトコル。
  既定はシステムの意味色で、ライト/ダークに自動追従する
- **付加機能は opt-in**: 50+ 言語のシンタックスハイライトと LaTeX 組版はそれぞれ別プロダクト。
  本体はどちらの依存も持たない

## 使い方

Markdown を描画する:

```swift
import SwiftUI
import SwiftMarkdownView

struct ArticleView: View {
    var body: some View {
        ScrollView {
            MarkdownView("""
            # Hello, Markdown!

            This is a **bold** and *italic* text.

            - [x] Task completed
            - [ ] Task pending
            """)
            .padding()
        }
    }
}
```

Markdown を編集する。エディタはプレーンな `String` にバインドする。行き来のための中間
ドキュメントモデルは無い:

```swift
import SwiftUI
import SwiftMarkdownEditor

struct NoteEditor: View {
    @State private var text = "# 下書き\n\n書き始める。"

    var body: some View {
        MarkdownEditor(text: $text)
    }
}
```

## ドキュメント

[API リファレンスとガイド](https://no-problem-dev.github.io/swift-markdown-view/documentation/swiftmarkdownview/) —
対応要素・テーマ・シンタックスハイライト・Aside・Mermaid ダイアグラム・エディタガイド。

動かせるサンプルアプリが [`Examples/`](./Examples) に 2 つある。`MarkdownPlayground`
（エディタ・要素カタログ・ブロックを跨いだ選択のショーケース）と `ZennArticleSwiftUI`
（実際の長文記事の描画）。

## インストール

`Package.swift` に追加する:

```swift
dependencies: [
    .package(url: "https://github.com/no-problem-dev/swift-markdown-view.git", from: "6.0.0")
]
```

必要な product をターゲットに追加する:

```swift
.target(
    name: "YourTarget",
    dependencies: [
        .product(name: "SwiftMarkdownView", package: "swift-markdown-view"),
        .product(name: "SwiftMarkdownEditor", package: "swift-markdown-view")
    ]
)
```

`SwiftMarkdownViewHighlightJS`（シンタックスハイライト）・`SwiftMarkdownViewLaTeX`（数式組版）・
2 つの `…DesignSystem` ブリッジは別 product で、必要な人だけが追加する。

## ライセンス

MIT — 詳細は [LICENSE](LICENSE) を参照。
