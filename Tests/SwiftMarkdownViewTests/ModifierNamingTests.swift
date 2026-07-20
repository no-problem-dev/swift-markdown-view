import Testing
import SwiftUI
import DesignSystem
@testable import SwiftMarkdownView

/// View modifier の命名と環境値の疎通。
///
/// `View` の extension はグローバル名前空間なので、`syntaxHighlighter` のような一般名を
/// 占有すると利用者のアプリや他ライブラリと衝突しうる。全て `markdown` prefix に統一し、
/// 旧名は deprecated エイリアスとして残している。
///
/// modifier が環境値に伝播する様子は、SwiftUI が実レンダリングなしに `body` を
/// 評価しないためヘッドレスでは観測できない。そこでここでは
/// ①環境キーの読み書きが成立すること ②新旧どちらの modifier 名も現在の型で
/// 呼び出せること（コンパイルが証明する）の 2 点に絞る。
@Suite("modifier の命名と環境値")
@MainActor
struct ModifierNamingTests {

    // MARK: 環境キーの読み書き

    @Test("画像方針の環境キーが読み書きできる")
    func imagePolicyEnvironmentKeyRoundTrips() {
        var env = EnvironmentValues()
        #expect(env.markdownImagePolicy == .default)

        env.markdownImagePolicy = .bundleOnly
        #expect(env.markdownImagePolicy == .bundleOnly)
        #expect(env.markdownImagePolicy.allowsRemoteImages == false)
    }

    @Test("レンダリングオプションの環境キーが読み書きできる")
    func renderingOptionsEnvironmentKeyRoundTrips() {
        var env = EnvironmentValues()
        #expect(env.markdownRenderingOptions.renderMath)

        env.markdownRenderingOptions = MarkdownRenderingOptions(renderMath: false)
        #expect(env.markdownRenderingOptions.renderMath == false)
    }

    // MARK: modifier の呼び出し可能性

    /// 新名がすべて現在の型で呼び出せることをコンパイルで保証する。
    /// シグネチャが壊れたらこのファイルがビルドできなくなる。
    @Test("markdown prefix つきの新名が揃っている")
    func prefixedModifiersExist() {
        let view = Color.clear
        _ = view.markdownSyntaxHighlighter(PlainTextHighlighter())
        _ = view.markdownImagePolicy(.bundleOnly)
        _ = view.markdownMermaidScriptProvider(CDNMermaidScriptProvider())
        _ = view.markdownRenderingOptions(.default)
        _ = view.markdownMathRenderer(PlainMathRenderer())
    }

    /// プロバイダーは先頭ドットで書ける。`any` を受ける実存パラメータだと
    /// 静的メンバの推論が効かないので、`some` で受けていることをコンパイルで保証する。
    @Test("プロバイダーを先頭ドットで指定できる")
    func providersUseLeadingDotSyntax() {
        let view = Color.clear
        _ = view.markdownMermaidScriptProvider(.cdn)
    }
}
