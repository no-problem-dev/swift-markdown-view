# シンタックスハイライト

コードブロックのシンタックスハイライトをカスタマイズする方法を学びます。

## Overview

SwiftMarkdownViewはデフォルトで``PlainTextHighlighter``を使用し、コードブロックに色付けは行いません。
50+言語に対応したシンタックスハイライトを有効にするには、オプションの`SwiftMarkdownViewHighlightJS`モジュールを使用します。

## クイックスタート

シンタックスハイライトを有効にするには：

```swift
import SwiftMarkdownViewHighlightJS

MarkdownView(source)
    .adaptiveSyntaxHighlighting()
```

これにより、ライト/ダークモードに自動対応し、アクセシビリティに配慮したa11yテーマが適用されます。

## HighlightJSの使用

`SwiftMarkdownViewHighlightJS`モジュールは50+言語に対応した正確なハイライトを提供します：

```swift
import SwiftMarkdownViewHighlightJS

// アダプティブハイライト（推奨）
MarkdownView(source)
    .adaptiveSyntaxHighlighting()

// テーマ指定
MarkdownView(source)
    .adaptiveSyntaxHighlighting(theme: .github)

// 手動設定
MarkdownView(source)
    .syntaxHighlighter(
        HighlightJSSyntaxHighlighter(theme: .atomOne, colorMode: .dark)
    )
```

### 利用可能なテーマ

| テーマ | 説明 |
|--------|------|
| `.a11y` | アクセシビリティ最適化（推奨） |
| `.xcode` | Xcodeデフォルトスタイル |
| `.github` | GitHubスタイル |
| `.atomOne` | Atom Oneスタイル |
| `.solarized` | Solarizedスタイル |
| `.tokyoNight` | Tokyo Nightスタイル |

### テーマプリセット

```swift
HighlightJSSyntaxHighlighter.xcodeLight
HighlightJSSyntaxHighlighter.xcodeDark
HighlightJSSyntaxHighlighter.githubLight
HighlightJSSyntaxHighlighter.githubDark
HighlightJSSyntaxHighlighter.atomOneLight
HighlightJSSyntaxHighlighter.atomOneDark
HighlightJSSyntaxHighlighter.a11yLight
HighlightJSSyntaxHighlighter.a11yDark
```

## カスタムハイライター

独自のシンタックスハイライトを実装するには、``SyntaxHighlighter``プロトコルに準拠したハイライターを作成します：

```swift
struct MyCustomHighlighter: SyntaxHighlighter {
    func highlight(_ code: String, language: String?) async throws -> AttributedString {
        var result = AttributedString(code)
        // カスタムハイライト処理を実装
        return result
    }
}

MarkdownView(source)
    .syntaxHighlighter(MyCustomHighlighter())
```

## シンタックスハイライトの無効化

デフォルトではシンタックスハイライトは適用されません。明示的にプレーンテキストを使用するには：

```swift
// デフォルト動作 - ハイライトなし
MarkdownView(source)

// 明示的にPlainTextHighlighterを使用
MarkdownView(source)
    .syntaxHighlighter(PlainTextHighlighter())
```

## アプリ全体への設定

アプリ全体にシンタックスハイライトを適用するには：

```swift
import SwiftMarkdownViewHighlightJS

@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .theme(ThemeProvider())
                .adaptiveSyntaxHighlighting()
        }
    }
}
```

## カタログでの使用

Markdownカタログでシンタックスハイライトを有効にするには：

```swift
import SwiftMarkdownViewHighlightJS

MarkdownCatalogView()
    .theme(ThemeProvider())
    .adaptiveSyntaxHighlighting()
```
