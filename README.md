# SwiftMarkdownView

[English](README_EN.md) | 日本語

SwiftUIネイティブなMarkdownレンダリングライブラリ。DesignSystemと統合し、シンタックスハイライトを備えた美しいMarkdown表示を実現します。

![Swift 6.0+](https://img.shields.io/badge/Swift-6.0+-orange.svg)
![iOS 17+](https://img.shields.io/badge/iOS-17+-blue.svg)
![macOS 14+](https://img.shields.io/badge/macOS-14+-purple.svg)
![License](https://img.shields.io/badge/License-MIT-green.svg)

## 特徴

- **SwiftUIネイティブ**: `AttributedString`と`Text`連結による高性能レンダリング
- **DesignSystem統合**: ColorPalette、Typography、Spacingとシームレスに連携
- **シンタックスハイライト**: 15言語対応（Swift, TypeScript, Python, Go, Rust等）
- **豊富な要素サポート**: テーブル、タスクリスト、画像、コードブロック等
- **カスタマイズ可能**: 環境値を通じたスタイル設定

## クイックスタート

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

        - [x] Task completed
        - [ ] Task pending
        """)
    }
}
```

## インストール

### Swift Package Manager

`Package.swift` に以下を追加：

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

## サポート要素

### ブロック要素

| 要素 | Markdown | サポート |
|------|----------|---------|
| 見出し | `# H1` ~ `###### H6` | ✅ |
| 段落 | テキスト | ✅ |
| コードブロック | ` ```swift ``` ` | ✅ |
| 引用 | `> quote` | ✅ |
| 順序なしリスト | `- item` | ✅ |
| 順序付きリスト | `1. item` | ✅ |
| タスクリスト | `- [x] done` | ✅ |
| テーブル | `\| col \|` | ✅ |
| 水平線 | `---` | ✅ |

### インライン要素

| 要素 | Markdown | サポート |
|------|----------|---------|
| 強調（イタリック） | `*text*` | ✅ |
| 太字 | `**text**` | ✅ |
| インラインコード | `` `code` `` | ✅ |
| リンク | `[text](url)` | ✅ |
| 画像 | `![alt](url)` | ✅ |
| 取り消し線 | `~~text~~` | ✅ |

### シンタックスハイライト対応言語

| 言語 | エイリアス |
|------|----------|
| Swift | `swift` |
| TypeScript | `typescript`, `ts`, `tsx` |
| JavaScript | `javascript`, `js`, `jsx` |
| Python | `python`, `py` |
| Go | `go`, `golang` |
| Rust | `rust`, `rs` |
| Java | `java` |
| Kotlin | `kotlin`, `kt` |
| Ruby | `ruby`, `rb` |
| Shell | `shell`, `bash`, `sh`, `zsh` |
| SQL | `sql` |
| HTML | `html`, `htm`, `xml` |
| CSS | `css`, `scss`, `sass`, `less` |
| JSON | `json` |
| YAML | `yaml`, `yml` |

## 高度な使用法

### カスタムシンタックストークナイザー

```swift
struct MyTokenizer: SyntaxTokenizer {
    func tokenize(_ code: String, language: String?) -> [SyntaxToken] {
        // カスタム実装
    }
}

MarkdownView("```swift\ncode\n```")
    .syntaxTokenizer(MyTokenizer())
```

### DesignSystemテーマの適用

```swift
MarkdownView("# Themed Markdown")
    .environment(\.colorPalette, .dark)
    .environment(\.typographyScale, .large)
```

## 依存関係

- [swift-markdown](https://github.com/swiftlang/swift-markdown) - Markdownパーシング
- [swift-design-system](https://github.com/no-problem-dev/swift-design-system) - デザイントークン

## ドキュメント

詳細なAPIドキュメントは [GitHub Pages](https://no-problem-dev.github.io/swift-markdown-view/documentation/swiftmarkdownview/) で確認できます。

## ライセンス

MIT License - 詳細は [LICENSE](LICENSE) を参照してください。
