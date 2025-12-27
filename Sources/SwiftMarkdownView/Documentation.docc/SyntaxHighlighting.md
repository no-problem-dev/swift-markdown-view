# シンタックスハイライト

コードブロックのシンタックスハイライトをカスタマイズする方法を学びます。

## Overview

SwiftMarkdownViewは15のプログラミング言語に対応したシンタックスハイライトを
内蔵しています。カスタムトークナイザーを実装することで、独自の言語サポートや
スタイルを追加することも可能です。

## 対応言語

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

## トークンタイプ

シンタックスハイライトは以下のトークンタイプに分類されます：

- `keyword`: 言語のキーワード（`func`, `class`, `if`等）
- `string`: 文字列リテラル
- `number`: 数値リテラル
- `comment`: コメント
- `type`: 型名
- `function`: 関数名
- `property`: プロパティ名
- `operator`: 演算子
- `preprocessor`: プリプロセッサディレクティブ
- `plain`: その他のテキスト

## カスタムトークナイザー

独自のシンタックスハイライトを実装する場合は、``SyntaxTokenizer``プロトコルに
準拠したトークナイザーを作成します。

```swift
struct MyCustomTokenizer: SyntaxTokenizer {
    func tokenize(_ code: String, language: String?) -> [SyntaxToken] {
        // カスタム実装
        var tokens: [SyntaxToken] = []
        // トークン化ロジック
        return tokens
    }
}
```

### トークナイザーの適用

```swift
MarkdownView("```swift\nlet x = 1\n```")
    .syntaxTokenizer(MyCustomTokenizer())
```

## カラーカスタマイズ

``SyntaxColors``を使用してシンタックスハイライトの色をカスタマイズできます。

```swift
// デフォルトカラーの取得
let colors = SyntaxColors.default

// トークンタイプに応じた色の適用
let keywordColor = colors.color(for: .keyword)
```
