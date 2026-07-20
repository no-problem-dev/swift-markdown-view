import SwiftUI
import SwiftMarkdownEditor

/// エディタの拡張点を一通り触れるデモ。
///
/// - ツールバーを項目配列で組み、既定に無いコマンド（マーカー）を足している
/// - コントローラを注入して、エディタの外からもコマンドを送っている
/// - `mode` を Binding にして現在の表示モードを観測している
struct EditorShowcaseView: View {

    @State private var text = """
    # 下書き

    **太字**・*斜体*・`コード` を打ってみる。

    - リストで Return を押すと次の項目が続く
    - [ ] タスクも書ける

    > 引用。

    ```swift
    let answer = 42
    ```
    """

    @State private var mode: MarkdownEditorMode = .edit
    @StateObject private var controller = MarkdownEditorController()

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Text("モード: \(mode.displayName)")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                Spacer()

                // エディタの外からコマンドを送る
                Button("太字") { controller.toggleBold() }
                Button("元に戻す") { controller.undo() }
                    .disabled(!controller.canUndo)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)

            Divider()

            MarkdownEditor(
                text: $text,
                mode: $mode,
                livePreview: false,
                toolbar: .standard + [
                    .separator,
                    .item(icon: "highlighter", label: "マーカー", key: "h") { controller in
                        guard let state = controller.state else { return }
                        controller.apply(MarkdownFormatting.wrap(
                            text: state.text,
                            selection: state.selection,
                            delimiter: "=="
                        ))
                    }
                ],
                controller: controller
            )
        }
        .navigationTitle("エディタ")
    }
}

#Preview {
    EditorShowcaseView()
}
