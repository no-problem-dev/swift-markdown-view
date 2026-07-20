import SwiftUI
import SwiftMarkdownEditorTextKit

/// ソースエディタ上部に表示されるフォーマットバー。
///
/// 項目は ``MarkdownEditorToolbarItem`` の配列で与える。各ボタンは
/// ``MarkdownEditorController`` を受け取り、テキストビューに変換を適用する。
///
/// 自前のモード UI と組み合わせたい場合は直接使ってよい:
///
/// ```swift
/// MarkdownFormattingToolbar(controller: controller, items: .standard)
/// ```
public struct MarkdownFormattingToolbar: View {

    private enum Metrics {
        static let itemSpacing: CGFloat = 4
        static let horizontalPadding: CGFloat = 8
        static let verticalPadding: CGFloat = 4
        static let iconSize: CGFloat = 15
        static let hitTarget: CGFloat = 28
        static let separatorHeight: CGFloat = 20
    }

    @ObservedObject private var controller: MarkdownEditorController
    private let items: [MarkdownEditorToolbarItem]

    /// - Parameters:
    ///   - controller: 操作対象のコントローラ。
    ///   - items: 表示する項目。既定は ``Swift/Array/standard``。
    public init(
        controller: MarkdownEditorController,
        items: [MarkdownEditorToolbarItem] = .standard
    ) {
        self.controller = controller
        self.items = items
    }

    public var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Metrics.itemSpacing) {
                ForEach(items) { item in
                    switch item.kind {
                    case .separator:
                        Divider().frame(height: Metrics.separatorHeight)
                    case .button(let button):
                        toolbarButton(button)
                    }
                }
            }
            .padding(.horizontal, Metrics.horizontalPadding)
            .padding(.vertical, Metrics.verticalPadding)
        }
    }

    /// アイコンだけのボタンにラベルとショートカットを与える。
    ///
    /// - アイコンには読み上げ名が無いので `accessibilityLabel` を必ず付ける。
    ///   付けないと VoiceOver ではボタン群が区別できない。
    /// - ショートカットはハードウェアキーボードのある iPad と macOS の双方で効く。
    @ViewBuilder
    private func toolbarButton(_ button: MarkdownEditorToolbarItem.Button) -> some View {
        let base = Button {
            button.action(controller)
        } label: {
            Image(systemName: button.icon)
                .font(.system(size: Metrics.iconSize))
                .frame(width: Metrics.hitTarget, height: Metrics.hitTarget)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(button.label)

        if let key = button.key {
            base.keyboardShortcut(key, modifiers: button.modifiers)
        } else {
            base
        }
    }
}
