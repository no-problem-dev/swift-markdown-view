# ``SwiftMarkdownView``

SwiftUIネイティブなMarkdownレンダリングライブラリ。

@Metadata {
    @PageColor(blue)
}

## Overview

SwiftMarkdownViewは、SwiftUIで美しいMarkdown表示を実現するライブラリです。
`AttributedString`と`Text`連結による高性能レンダリング、DesignSystemとの統合、
オプショナルな50+言語対応シンタックスハイライトを備えています。

### 特徴

- **SwiftUIネイティブ**: `AttributedString`と`Text`連結による高性能レンダリング
- **DesignSystem統合**: ColorPalette、Typography、Spacingとシームレスに連携
- **シンタックスハイライト**: オプショナルモジュールで50+言語対応
- **Mermaidダイアグラム**: フローチャート、シーケンス図等をサポート
- **Aside（コールアウト）**: Note、Warning、Tipなど24種類 + カスタム
- **豊富な要素サポート**: テーブル、タスクリスト、画像等

### パッケージ構成

このパッケージは2つのモジュールで構成されています：

| モジュール | 用途 |
|-----------|------|
| **SwiftMarkdownView** | Markdownレンダリングのコアモジュール |
| **SwiftMarkdownViewHighlightJS** | HighlightJSによるシンタックスハイライト（オプション） |

### クイックスタート

```swift
import SwiftUI
import SwiftMarkdownView

struct ContentView: View {
    var body: some View {
        MarkdownView("""
        # Hello, Markdown!

        This is a **bold** and *italic* text.

        ```swift
        let greeting = "Hello, World!"
        print(greeting)
        ```
        """)
    }
}
```

### シンタックスハイライトを有効にする

```swift
import SwiftMarkdownView
import SwiftMarkdownViewHighlightJS

MarkdownView(source)
    .adaptiveSyntaxHighlighting()
```

## Topics

### はじめに

- ``MarkdownView``
- ``MarkdownContent``
- <doc:GettingStarted>

### シンタックスハイライト

- ``SyntaxHighlighter``
- ``PlainTextHighlighter``
- ``HighlightState``
- ``HighlightedCodeView``
- <doc:SyntaxHighlighting>

### Aside（コールアウト）

- ``DefaultAsideStyle``
- <doc:Asides>

### Mermaidダイアグラム

- <doc:MermaidDiagrams>

### ドメインモデル

- ``MarkdownBlock``
- ``MarkdownInline``
- ``AsideKind``
- ``TableData``
- ``ListItem``

### スタイル

- ``LinkStyle``
- ``CodeBlockStyle``
- ``TableStyle``
- ``AsideStyle``

### Mermaid

- ``MermaidDiagramView``
- ``AdaptiveMermaidView``
- ``MermaidFallbackView``

## 関連モジュール

**SwiftMarkdownViewHighlightJS**: HighlightJSによる50+言語対応シンタックスハイライト

シンタックスハイライトを使用するには、別途`SwiftMarkdownViewHighlightJS`モジュールをインポートしてください。
