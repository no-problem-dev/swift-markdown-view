---
title: "Codableの延長線で考える、Swift Foundation ModelsによるLLMデコード"
emoji: "🧠"
type: "tech"
topics: ["swift", "swiftui", "ios", "llm", "foundationmodels"]
published: true
---

## 目次

1. [はじめに](#1-はじめに)
2. [Foundation Modelsの概要](#2-foundation-modelsの概要)
3. [アプリでLLMを使いたいとき](#3-アプリでllmを使いたいとき)
4. [LLMCodableの設計思想](#4-llmcodableの設計思想)
5. [API設計とプロトコル構成](#5-api設計とプロトコル構成)
6. [実装のポイント](#6-実装のポイント)
7. [まとめ](#7-まとめ)

---

## 1. はじめに

本記事では、iOS/macOS 26で導入されたFoundation Modelsフレームワークを使って、Codableライクなインターフェースで曖昧なテキストを構造化データに変換するライブラリ「[LLMCodable](https://github.com/no-problem-dev/LLMCodable)」について解説します。この記事では、私が開発する際に考えた設計思想やライブラリ自体の使い方を紹介していきます。

まずFoundation Modelsの概要を説明し、次にアプリでLLMを使う際の使い分けについて考えます。その上で、LLMCodableの設計思想とAPI設計、実装のポイントを順に解説していきます。

---

## 2. Foundation Modelsの概要

Foundation Modelsは、iOS/macOS 26で導入されたAppleのオンデバイスLLMフレームワークです。裏側では[Apple Intelligence](https://www.apple.com/apple-intelligence/)のローカル言語モデルが動作します。

### オンデバイスモデルのスペック

[Appleの公式発表](https://machinelearning.apple.com/research/apple-foundation-models-2025-updates)によると、オンデバイスモデルは約30億パラメータで、最大65,000トークンのコンテキスト長をサポートします。2ビット量子化によりApple Silicon向けに最適化されており、15言語に対応しています。

要約、エンティティ抽出、テキスト分類、短い対話生成などのタスクに適しています。一方で、複雑な推論、数学、コード生成、最新の世界知識を必要とするタスクには向いていません。ベンチマークでは[Qwen2.5-3B](https://huggingface.co/Qwen/Qwen2.5-3B)を上回り、より大きな[Qwen3-4B](https://huggingface.co/Qwen/Qwen3-4B)や[Gemma-3-4B](https://huggingface.co/google/gemma-3-4b-it)と英語で同等の性能を示しています。

なお、実際に使ってみた所感として、日本語での対話生成は精度が厳しい印象です。エンティティ抽出や分類といったシンプルなタスクであれば日本語でも十分機能しますが、自然な対話を期待する場合は英語のほうが安定します。

### 基本的な使い方

`@Generable`マクロを付けた型を定義し、`LanguageModelSession`の`respond(generating:)`メソッドを呼ぶことで、LLMの出力を直接Swiftの型としてデコードできます。

```swift
import FoundationModels

@Generable
struct Person {
    @Guide(description: "The person's full name")
    var name: String

    @Guide(description: "Age in years")
    var age: Int
}

let session = LanguageModelSession()
let response = try await session.respond(generating: Person.self) {
    "田中太郎は35歳です"
}
// response.content: Person(name: "田中太郎", age: 35)
```

`@Generable`マクロは型をLLMが理解できる形式に変換します。`@Guide`マクロは各プロパティの意味をLLMに伝えるためのもので、descriptionには英語で正確な説明を記述する必要があります。

オンデバイスで動作するため、外部APIへの通信は不要です。

---

## 3. アプリでLLMを使いたいとき

私は、アプリでLLMを使いたいケースは大きく2つに分かれると考えています。

**外部の推論モデルが必要な場合**

高度な推論や長文生成が必要なら、OpenAI、Anthropic、GoogleなどのAPIを利用するのが現実的です。アプリから直接外部APIを叩くのはAPIキー管理の観点から避けたいので、自前のバックエンドにエンドポイントを用意することになります。

**オンデバイスの小規模モデルで十分な場合**

一方で、ルールベースでは実装が難しいが、外部のLLM APIを使うほどでもない、というケースがあります。

典型的な例が、曖昧なテキストを構造化データに変換する処理です。

```
入力: "田中さん、30代くらい、会社員"
出力: Person(name: "田中", age: 30, occupation: "会社員")
```

この処理はルールベースのパーサーでは難しいですが、外部のLLM APIを利用するためにバックエンドを用意するのは過剰です。Foundation Modelsを使えば、オンデバイスで完結できます。

この2番目のケースに対して、Foundation Modelsをラップしたライブラリを設計すれば、シンプルに解決できるのではないかと考えました。それがLLMCodableです。

---

## 4. LLMCodableの設計思想

### やりたいことの本質

「曖昧なテキストを構造化データに変換する」という処理を考えたとき、これは`Decodable`の役割と本質的に同じだと気づきました。

| プロトコル | 入力型 | 入力の性質 | 出力 |
|-----------|--------|-----------|------|
| `Decodable` | `Data` | 構造化されたデータ（JSON等） | 準拠した任意の型 |
| `LLMDecodable` | `StringProtocol` | 曖昧なテキスト | 準拠した任意の型 |

どちらも「ある形式のテキストをSwiftの型に変換する」という責務です。

### AI部分を隠蔽する

ここで重要なのは、**やりたいことの責務はAIとは無関係**ということです。

LLMは実装手段に過ぎません。曖昧なテキストの解釈はルールベースでは難しいため、現状LLMが最も適した実装手段ですが、それでも利用者がLLMの存在を意識する必要はありません。

だからこそ、**AI部分をAPIから隠蔽する**ことが設計の肝になります。

利用者は`Codable`を使うときにJSONパーサーの実装を意識しないのと同様に、`LLMCodable`を使うときもLLMの存在を意識しなくていい。そういうAPIを目指しました。

とはいえ、ライブラリ名自体には`LLM`を含めています。これは「LLMを利用してCodable的なことを実現する」という前提を明示するためです。`import LLMCodable`の時点でその前提は共有されるため、個々のメソッド名（`decode(as:)`など）にはLLMを含めていません。結果として、利用時のコードは`Codable`と同じような使い心地になります。

---

## 5. API設計とプロトコル構成

### プロトコル構成

3つのプロトコルを用意しました。

```swift
public protocol LLMDecodable: Generable { ... }

public protocol LLMEncodable: Encodable { ... }

public typealias LLMCodable = LLMDecodable & LLMEncodable
```

`LLMDecodable`は`Generable`を継承しているため、`@Generable`を付けた型は自動的にデフォルト実装が提供されます。

### 使い方

```swift
import FoundationModels
import LLMCodable

@Generable
struct Person: LLMCodable {
    @Guide(description: "The person's full name")
    var name: String

    @Guide(description: "Age in years")
    var age: Int
}

let input: String = "谷口恭一は24歳のiOSエンジニアです"
let person = try await input.decode(as: Person.self)
```

`StringProtocol`の拡張として`decode(as:)`を提供することで、テキストから直接デコードできます。

![基本デコードのデモ](/images/llmcodable-basic-decode.gif =280x)

### プロパティ単位のストリーミング

LLMがプロパティを生成するたびに、その値を逐次取得できます。

```swift
let stream = try input.decodeStream(as: MovieReview.self)
for try await partial in stream {
    if let title = partial.title {
        self.title = title
    }
}
```

![プロパティ単位のストリーミングのデモ](/images/llmcodable-property-streaming.gif =280x)

### 配列要素のストリーミング

配列の各要素が完成するたびに取得することもできます。

```swift
let stream = input.decodeElements(of: Recipe.self)
for try await recipe in stream {
    recipes.append(recipe)
}
```

![配列要素のストリーミングのデモ](/images/llmcodable-array-streaming.gif =280x)

### 信頼度スコア

入力テキストの曖昧さに基づいて、抽出の信頼度を0.0〜1.0で取得できます。

```swift
let ambiguousInput: String = "多分30歳くらいの田中さん"
let result = try await ambiguousInput.decodeWithConfidence(as: Person.self)
print(result.confidence)
```

![信頼度スコアのデモ](/images/llmcodable-confidence.gif =280x)

---

## 6. 実装のポイント

実装は非常にシンプルです。

### 基本のデコード

`LanguageModelSession.respond(generating:)`をラップするだけです。

```swift
public static func decode<S: StringProtocol>(
    from input: S,
    using session: LanguageModelSession,
    options: GenerationOptions
) async throws -> Self {
    let response = try await session.respond(
        generating: Self.self,
        options: options
    ) {
        Prompt("Extract structured data from the following text:\n\n\(input)")
    }
    return response.content
}
```

### 信頼度スコア

信頼度スコアは、一度デコードした後にLLMへ信頼度を評価させる2段階アプローチで実装しています。

```swift
// 1. まずデコード
let value = try await decode(from: input, using: session, options: options)

// 2. 信頼度を評価
let confidenceResponse = try await session.respond(
    generating: ConfidenceWrapper.self,
    options: options
) {
    Prompt("""
        You just extracted structured data from the following text:
        "\(input)"
        Based on the clarity, completeness, and ambiguity of this input text,
        evaluate your confidence in the accuracy of the extraction.
        """)
}

return DecodedResult(value: value, confidence: confidenceResponse.content.confidence)
```

Foundation Modelsが提供する機能をそのまま活用しているため、ライブラリ側で複雑なことをする必要はありません。

---

## 7. まとめ

Foundation Modelsの登場により、オンデバイスでのLLM利用が現実的になりました。

LLMCodableは、「曖昧なテキストを構造化データに変換する」という責務に集中し、Codableの延長線上にあるAPIを提供します。LLMという実装手段を隠蔽することで、利用者はAIを意識せずに構造化変換を行えます。

高度な推論が必要なら外部の推論モデル、軽い用途ならオンデバイスのFoundation Modelsという使い分けを意識した上で、後者で十分なケースにはぜひLLMCodableを試してみてください。

---

## 参考リンク

### 本記事で紹介したライブラリ
- [LLMCodable](https://github.com/no-problem-dev/LLMCodable) - Foundation Modelsを使ったCodableライクなLLMデコード

### 著者
- [GitHub](https://github.com/taniguchi-kyoichi)
