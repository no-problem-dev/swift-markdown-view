import SwiftUI
import DesignSystem

/// 埋め込み数式をインラインで組版するシングルラインテキストビュー。
///
/// ``MarkdownView`` と異なり、ブロック構造を解析しない。ソースはテキストと
/// 数式セグメントのみに分割されるため、呼び出し元のフォントを継承した
/// `Text` コンポジションが返る。Markdown ボディレイアウトが不要だが
/// LLM 出力に `$...$` / `$$...$$` デリミタが含まれる可能性がある
/// 見出し・ラベルなどで使用する:
///
/// ```swift
/// MathText("答え: $$-6$$", mathFontSize: 22)
///     .font(.title2)
/// ```
///
/// ディスプレイ数式（`$$...$$`、`\[...\]`）はシングルラインにブロックレイアウトがないため、
/// インラインモードで組版する。数式は環境の ``MathRenderer`` 経由でレンダリングされ、
/// レンダラーが注入されない場合は LaTeX ソースを等幅テキストで表示する。
public struct MathText: View {

    private let source: String
    private let mathFontSize: CGFloat?

    @Environment(\.mathRenderer) private var renderer
    @Environment(\.colorPalette) private var colorPalette
    @Environment(\.markdownRenderingOptions) private var options

    /// - Parameters:
    ///   - source: 数式デリミタを含む可能性があるテキスト。
    ///   - mathFontSize: 数式セグメントのポイントサイズ。通常は周囲のフォントのサイズを指定する。
    ///     `nil` の場合はレンダラーのデフォルトを使用する。
    public init(_ source: String, mathFontSize: CGFloat? = nil) {
        self.source = source
        self.mathFontSize = mathFontSize
    }

    public var body: some View {
        composed
    }

    private var composed: Text {
        guard options.renderMath else { return Text(source) }
        var output = Text(verbatim: "")
        for part in MathScanner.parts(in: source) {
            switch part {
            case .text(let text):
                output = output + Text(text)
            case .math(let latex, _, _):
                if let mathFontSize {
                    output = output + renderer.inlineMath(latex, fontSize: mathFontSize, palette: colorPalette)
                } else {
                    output = output + renderer.inlineMath(latex, palette: colorPalette)
                }
            }
        }
        return output
    }
}
