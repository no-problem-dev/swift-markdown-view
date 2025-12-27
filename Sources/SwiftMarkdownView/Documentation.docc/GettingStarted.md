# はじめに

SwiftMarkdownViewを使ってMarkdownを表示する基本的な方法を学びます。

## Overview

SwiftMarkdownViewは、SwiftUIアプリケーションでMarkdownテキストを
美しくレンダリングするためのライブラリです。

## インストール

### Swift Package Manager

`Package.swift`に以下を追加してください：

```swift
dependencies: [
    .package(url: "https://github.com/no-problem-dev/swift-markdown-view.git", from: "1.0.0")
]
```

ターゲットに追加：

```swift
.target(
    name: "YourTarget",
    dependencies: [
        .product(name: "SwiftMarkdownView", package: "swift-markdown-view")
    ]
)
```

## 基本的な使い方

### シンプルな表示

```swift
import SwiftUI
import SwiftMarkdownView

struct ContentView: View {
    var body: some View {
        MarkdownView("# Hello, World!")
    }
}
```

### 複雑なMarkdown

```swift
MarkdownView("""
# タイトル

これは**太字**と*イタリック*のテキストです。

## リスト

- アイテム1
- アイテム2
- アイテム3

## コードブロック

```swift
let greeting = "Hello!"
print(greeting)
```

## タスクリスト

- [x] 完了したタスク
- [ ] 未完了のタスク
""")
```

## DesignSystemとの統合

SwiftMarkdownViewは[swift-design-system](https://github.com/no-problem-dev/swift-design-system)と
統合されており、テーマに応じた表示が可能です。

```swift
MarkdownView("# Themed Markdown")
    .environment(\.colorPalette, .dark)
    .environment(\.typographyScale, .large)
```

## 次のステップ

- <doc:SyntaxHighlighting>: シンタックスハイライトのカスタマイズ方法
