# はじめかた

`SwiftMarkdownView` で Markdown をレンダリングする基本を学ぶ。

## Overview

`SwiftMarkdownView` はシングルインポートで任意の SwiftUI アプリに Markdown レンダリングを追加できる。CommonMark と GitHub Flavored Markdown を解析し、見出し・コードブロック・テーブル・タスクリスト・Aside・画像などをネイティブ SwiftUI としてレンダリングし、`swift-design-system` テーマを自動的に適用する。

## インストール

### Swift Package Manager

`Package.swift` に依存関係を追加する:

```swift
dependencies: [
    .package(
        url: "https://github.com/no-problem-dev/swift-markdown-view.git",
        .upToNextMajor(from: "1.4.3")
    )
]
```

次に、ターゲットにプロダクトを追加する:

```swift
.target(
    name: "YourTarget",
    dependencies: [
        .product(name: "SwiftMarkdownView", package: "swift-markdown-view")
    ]
)
```

シンタックスハイライトを有効にするには、`SwiftMarkdownViewHighlightJS` も追加する:

```swift
.product(name: "SwiftMarkdownViewHighlightJS", package: "swift-markdown-view")
```

## 基本的な使い方

### 文字列をレンダリングする

Markdown 文字列を ``MarkdownView`` に直接渡す:

```swift
import SwiftUI
import SwiftMarkdownView

struct ContentView: View {
    var body: some View {
        ScrollView {
            MarkdownView("""
            # Hello, Markdown!

            This is **bold**, *italic*, and `inline code`.

            ## Lists

            - Item one
            - Item two
            - [x] Completed task

            ```swift
            let message = "Hello, World!"
            print(message)
            ```
            """)
            .padding()
        }
    }
}
```

### パフォーマンス向上のための事前パース

同じ Markdown を複数箇所で表示する場合やメインスレッド外で解析する場合は、``MarkdownContent`` を直接使用する:

```swift
let content = MarkdownContent(parsing: longMarkdownString)

// 後でメインスレッドで:
MarkdownView(content)
```

### 見た目を調整する

既定はシステムの意味色なので、設定なしでライト/ダークどちらでも文字が読める。
自分の配色に合わせるには ``MarkdownPalette`` を実装する:

```swift
struct BrandPalette: MarkdownPalette {
    var text: Color { .primary }
    var secondaryText: Color { .secondary }
    var heading: Color { .indigo }
    var link: Color { .blue }
    var codeBackground: Color { Color.gray.opacity(0.12) }
    var rule: Color { Color.gray.opacity(0.4) }
}

MarkdownView(source)
    .markdownPalette(BrandPalette())
```

`swift-design-system` を使っているなら `SwiftMarkdownViewDesignSystem` を追加して
`.markdownTheme(themeProvider)` を呼ぶとアプリテーマに追従する。

### シンタックスハイライトを有効にする

ターゲットに `SwiftMarkdownViewHighlightJS` を追加し（上記インストール参照）、次のようにする:

```swift
import SwiftMarkdownViewHighlightJS

MarkdownView(source)
    .adaptiveSyntaxHighlighting()   // automatic light/dark theme
```

## 次のステップ

- <doc:SyntaxHighlighting>
- <doc:Asides>
- <doc:MermaidDiagrams>
