import Testing
@testable import SwiftMarkdownEditorCore

/// インデントに関するブロック判定が、プレビュー側（swift-markdown）と食い違わないことの検証。
///
/// エディタとプレビューは分割表示で同じ文書を並べて出す。ここが食い違うと、同じ行が
/// 左ではコード・右では見出しとして描かれる。
@Suite("トークナイザのインデント判定")
struct MarkdownTokenizerIndentTests {

    private func kinds(_ text: String) -> [MarkdownToken.Kind] {
        MarkdownTokenizer.tokenize(text).map(\.kind)
    }

    // MARK: インデントコードブロック（B-12）

    @Test("4 スペースのインデントコードは見出しにならない")
    func indentedCodeIsNotHeading() {
        let result = kinds("para\n\n    # not a heading\n")
        #expect(!result.contains(.headingMarker))
        #expect(result.contains(.codeBlock))
    }

    @Test("4 スペースのインデントコードは強調にならない")
    func indentedCodeIsNotStrong() {
        let result = kinds("para\n\n    **not bold**\n")
        #expect(!result.contains(.strong))
        #expect(result.contains(.codeBlock))
    }

    @Test("インデントコードは空行を挟んでも継続する")
    func indentedCodeSurvivesBlankLine() {
        // CommonMark 4.4: 空行はインデントコードを終わらせない。
        let result = kinds("para\n\n    a\n\n    # b\n")
        #expect(!result.contains(.headingMarker))
    }

    @Test("インデントが 4 未満に戻るとインデントコードは終わる")
    func indentedCodeEndsWhenDedented() {
        let result = kinds("para\n\n    code\n\n# heading\n")
        #expect(result.contains(.headingMarker))
    }

    @Test("インデントコードは段落を中断しない")
    func indentedCodeCannotInterruptParagraph() {
        // 直前が空行でないので、これはコードではなく段落の継続行。
        let result = kinds("para\n    # still a heading candidate\n")
        #expect(!result.contains(.codeBlock))
    }

    @Test("3 スペースまではインデントコードにならない")
    func threeSpacesIsNotIndentedCode() {
        let result = kinds("para\n\n   # heading\n")
        #expect(result.contains(.headingMarker))
        #expect(!result.contains(.codeBlock))
    }

    // MARK: 開きフェンスのインデント上限（B-13）

    @Test("段落の継続行の字下げされた ``` はフェンスを開かない")
    func indentedFenceDoesNotOpenAfterParagraph() {
        // 開くと、以降の文書全体がコードとして着色され続ける。
        let result = kinds("para\n    ```\n    code\n    ```\ntail\n")
        #expect(!result.contains(.codeFence))
    }

    @Test("3 スペースまでのインデントなら開きフェンスとして有効")
    func threeSpaceIndentedFenceStillOpens() {
        let result = kinds("   ```\ncode\n   ```\n")
        #expect(result.contains(.codeFence))
        #expect(result.contains(.codeBlock))
    }

    @Test("インデントなしのフェンスは従来どおり")
    func plainFenceStillOpens() {
        let result = kinds("```swift\nlet a = 1\n```\n")
        #expect(result.filter { $0 == .codeFence }.count == 2)
        #expect(result.contains(.codeBlock))
    }

    @Test("リスト項目内の字下げされた閉じフェンスは従来どおり閉じる")
    func indentedClosingFenceStillCloses() {
        // 閉じ側のインデント無制限は前セッションの修正として意図的。退行させない。
        let result = kinds("- item\n\n  ```\n  code\n  ```\n\n# after\n")
        #expect(result.contains(.headingMarker))
    }
}
