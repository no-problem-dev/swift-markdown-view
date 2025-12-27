# ``SwiftMarkdownView``

SwiftUIネイティブなMarkdownレンダリングライブラリ。

## Overview

SwiftMarkdownViewは、SwiftUIで美しいMarkdown表示を実現するライブラリです。
`AttributedString`と`Text`連結による高性能レンダリング、DesignSystemとの統合、
15言語対応のシンタックスハイライトを備えています。

### 特徴

- **SwiftUIネイティブ**: `AttributedString`と`Text`連結による高性能レンダリング
- **DesignSystem統合**: ColorPalette、Typography、Spacingとシームレスに連携
- **シンタックスハイライト**: 15言語対応（Swift, TypeScript, Python, Go, Rust等）
- **豊富な要素サポート**: テーブル、タスクリスト、画像、コードブロック等
- **カスタマイズ可能**: 環境値を通じたスタイル設定

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

## Topics

### 基本的な使い方

- ``MarkdownView``
- <doc:GettingStarted>

### Code Blocks and Syntax Highlighting

- ``SyntaxHighlighter``
- ``RegexSyntaxHighlighter``
- ``SyntaxColorScheme``
- ``HighlightState``
- ``HighlightedCodeView``
- <doc:SyntaxHighlighting>

### レンダリングカスタマイズ

- ``BlockRenderer``
- ``InlineRenderer``
- ``MarkdownEnvironmentValues``
