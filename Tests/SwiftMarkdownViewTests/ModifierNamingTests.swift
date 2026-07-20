import Testing
import SwiftUI
import DesignSystem
@testable import SwiftMarkdownView

/// View modifier の命名と環境値の疎通。
///
/// `View` の extension はグローバル名前空間なので、`headingStyle` や `codeBlockStyle` の
/// ような一般名を占有すると利用者のアプリや他ライブラリと衝突しうる。全て `markdown`
/// prefix に統一し、旧名は deprecated エイリアスとして残している。
///
/// modifier が環境値に伝播する様子は、SwiftUI が実レンダリングなしに `body` を
/// 評価しないためヘッドレスでは観測できない。そこでここでは
/// ①環境キーの読み書きが成立すること ②新旧どちらの modifier 名も現在の型で
/// 呼び出せること（コンパイルが証明する）の 2 点に絞る。
@Suite("modifier の命名と環境値")
@MainActor
struct ModifierNamingTests {

    // MARK: 環境キーの読み書き

    @Test("スタイルの環境キーが読み書きできる")
    func styleEnvironmentKeysRoundTrip() {
        var env = EnvironmentValues()

        env.headingStyle = ColoredHeadingStyle()
        env.codeBlockStyle = TerminalCodeBlockStyle()
        env.asideStyle = DefaultAsideStyle()
        env.markdownTableStyle = StripedTableStyle()
        env.markdownLinkStyle = SubtleLinkStyle()

        #expect(env.headingStyle is ColoredHeadingStyle)
        #expect(env.codeBlockStyle is TerminalCodeBlockStyle)
        #expect(env.asideStyle is DefaultAsideStyle)
        #expect(env.markdownTableStyle is StripedTableStyle)
        #expect(env.markdownLinkStyle is SubtleLinkStyle)
    }

    @Test("画像方針の環境キーが読み書きできる")
    func imagePolicyEnvironmentKeyRoundTrips() {
        var env = EnvironmentValues()
        #expect(env.markdownImagePolicy == .default)

        env.markdownImagePolicy = .bundleOnly
        #expect(env.markdownImagePolicy == .bundleOnly)
        #expect(env.markdownImagePolicy.allowsRemoteImages == false)
    }

    // MARK: modifier の呼び出し可能性

    /// 新名がすべて現在の型で呼び出せることをコンパイルで保証する。
    /// シグネチャが壊れたらこのファイルがビルドできなくなる。
    @Test("markdown prefix つきの新名が揃っている")
    func prefixedModifiersExist() {
        let view = Color.clear
        _ = view.markdownHeadingStyle(ColoredHeadingStyle())
        _ = view.markdownCodeBlockStyle(TerminalCodeBlockStyle())
        _ = view.markdownAsideStyle(DefaultAsideStyle())
        _ = view.markdownTableStyle(StripedTableStyle())
        _ = view.markdownLinkStyle(SubtleLinkStyle())
        _ = view.markdownSyntaxHighlighter(PlainTextHighlighter())
        _ = view.markdownImagePolicy(.bundleOnly)
        _ = view.markdownMermaidScriptProvider(CDNMermaidScriptProvider())
    }

    /// 旧名は deprecated だが削除ではない。利用者のコードが動き続けることを保証する。
    @Test("旧名も引き続き呼び出せる")
    @available(*, deprecated)
    func deprecatedAliasesStillCallable() {
        let view = Color.clear
        _ = view.headingStyle(ColoredHeadingStyle())
        _ = view.codeBlockStyle(TerminalCodeBlockStyle())
        _ = view.asideStyle(DefaultAsideStyle())
        _ = view.syntaxHighlighter(PlainTextHighlighter())
        _ = view.mermaidScriptProvider(CDNMermaidScriptProvider())
    }
}
