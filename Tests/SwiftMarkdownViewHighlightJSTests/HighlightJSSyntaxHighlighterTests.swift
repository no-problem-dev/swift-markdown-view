import Testing
import Foundation
import SwiftUI
@testable import SwiftMarkdownViewHighlightJS

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// シンタックスハイライタの検証。
///
/// 「結果が空でない」だけでは、入力をそのまま返す実装（＝ハイライトしない実装）でも通ってしまう。
/// ここで守るのは ①文字列が保存されること ②実際に複数の色が付くこと
/// ③テーマ・カラーモードが結果に効くこと の 3 点。
@Suite("HighlightJS Syntax Highlighter")
struct HighlightJSSyntaxHighlighterTests {

    /// 付与された前景色の集合。ハイライトが機能していれば 2 色以上になる。
    ///
    /// 色は SwiftUI の `foregroundColor` ではなく AppKit/UIKit の色として入っている。
    /// 実際の消費側（`MarkdownSyntaxHighlighting.applyForegroundColors`）も
    /// `NSAttributedString` に変換して `.foregroundColor` を読むので、同じ経路で確認する。
    private func foregroundColors(_ attributed: AttributedString) -> Set<String> {
        let ns = NSAttributedString(attributed)
        var colors: Set<String> = []
        ns.enumerateAttribute(.foregroundColor, in: NSRange(location: 0, length: ns.length)) { value, _, _ in
            if let value { colors.insert(String(describing: value)) }
        }
        return colors
    }

    @Test("Swift コードが複数色にハイライトされる")
    func highlightsSwiftCode() async throws {
        let code = """
        func greet(_ name: String) -> String {
            return "Hello, \\(name)!"
        }
        """
        let result = try await HighlightJSSyntaxHighlighter().highlight(code, language: "swift")

        // 文字列は変更されない（ハイライトは属性であって内容ではない）。
        #expect(String(result.characters) == code)
        // キーワード・文字列リテラル・地の文で色が分かれる。
        #expect(foregroundColors(result).count >= 2)
    }

    @Test("Python コードが複数色にハイライトされる")
    func highlightsPythonCode() async throws {
        let code = """
        def greet(name: str) -> str:
            return f"Hello, {name}!"
        """
        let result = try await HighlightJSSyntaxHighlighter().highlight(code, language: "python")

        #expect(String(result.characters) == code)
        #expect(foregroundColors(result).count >= 2)
    }

    @Test("言語未指定でも自動判定してハイライトする")
    func autoDetectsLanguage() async throws {
        let code = """
        function greet(name) {
            return `Hello, ${name}!`;
        }
        """
        let highlighter = HighlightJSSyntaxHighlighter()
        let detected = try await highlighter.highlight(code, language: nil)
        let explicit = try await highlighter.highlight(code, language: "javascript")

        // 自動判定が効いていれば、明示指定と同じ色付けになる。
        #expect(String(detected.characters) == code)
        #expect(foregroundColors(detected).count >= 2)
        #expect(foregroundColors(detected) == foregroundColors(explicit))
    }

    @Test("空文字列は空のまま返る")
    func handlesEmptyCode() async throws {
        let result = try await HighlightJSSyntaxHighlighter().highlight("", language: "swift")
        #expect(result.characters.isEmpty)
    }

    @Test("テーマが違えば配色も違う")
    func themeAffectsColors() async throws {
        let code = "let x = 42"
        let github = try await HighlightJSSyntaxHighlighter(theme: .github, colorMode: .dark)
            .highlight(code, language: "swift")
        let xcode = try await HighlightJSSyntaxHighlighter(theme: .xcode, colorMode: .dark)
            .highlight(code, language: "swift")

        #expect(foregroundColors(github) != foregroundColors(xcode))
    }

    @Test("カラーモードが違えば配色も違う")
    func colorModeAffectsColors() async throws {
        let code = "let x = 42"
        let light = try await HighlightJSSyntaxHighlighter(theme: .xcode, colorMode: .light)
            .highlight(code, language: "swift")
        let dark = try await HighlightJSSyntaxHighlighter(theme: .xcode, colorMode: .dark)
            .highlight(code, language: "swift")

        #expect(foregroundColors(light) != foregroundColors(dark))
    }

    @Test("プリセットはテーマとカラーモードの組み合わせが正しい")
    func presetsPairThemeAndMode() async throws {
        let code = "let x = 42"
        let preset = try await HighlightJSSyntaxHighlighter.xcodeDark.highlight(code, language: "swift")
        let manual = try await HighlightJSSyntaxHighlighter(theme: .xcode, colorMode: .dark)
            .highlight(code, language: "swift")

        #expect(foregroundColors(preset) == foregroundColors(manual))
    }

    @Test("light と dark のプリセットは別物")
    func lightAndDarkPresetsDiffer() async throws {
        let code = "let x = 42"
        let light = try await HighlightJSSyntaxHighlighter.xcodeLight.highlight(code, language: "swift")
        let dark = try await HighlightJSSyntaxHighlighter.xcodeDark.highlight(code, language: "swift")

        #expect(foregroundColors(light) != foregroundColors(dark))
    }
}
