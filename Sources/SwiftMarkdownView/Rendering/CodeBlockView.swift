import SwiftUI
import DesignSystem

/// コードブロックを SwiftUI ビューとして描画する。
///
/// 本文のレンダリングは TextKit 2 バックエンドが担うため、このビューが使われるのは
/// ``MathRenderer`` のフォールバック経路 — LaTeX レンダラが導入されていない、あるいは
/// 数式描画が無効な場合に、数式を等幅のコードブロックとして見せるとき。
struct CodeBlockView: View {
    let language: String?
    let code: String

    @Environment(\.colorPalette) private var colorPalette
    @Environment(\.spacingScale) private var spacing
    @Environment(\.radiusScale) private var radius

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let language, !language.isEmpty {
                Text(language)
                    .typography(.labelSmall)
                    .foregroundStyle(MarkdownColors.codeText(colorPalette))
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HighlightedCodeView(
                    code: trimmedCode,
                    language: language
                )
            }
            .padding(MarkdownSpacing.codeBlockPadding(spacing))
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(MarkdownColors.codeBlockBackground(colorPalette))
            .clipShape(RoundedRectangle(cornerRadius: MarkdownRadius.codeBlock(radius)))
        }
    }

    private var trimmedCode: String {
        code.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
