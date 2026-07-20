import SwiftUI
import SwiftMarkdownView
import SwiftMarkdownEditorCore
import SwiftMarkdownEditorRules
import SwiftMarkdownEditorTextKit

/// ライブシンタックスハイライト・フォーマットツールバー・レンダリングプレビューを備えた SwiftUI Markdown エディタ。
///
/// ```swift
/// @State private var text = "# Hello"
/// var body: some View {
///     MarkdownEditor(text: $text)
/// }
/// ```
///
/// `text` のプレーン Markdown 文字列が唯一の正。
/// 編集は TextKit 2 テキストビュー上で行われ、プレビューは ``MarkdownView`` を再利用するため
/// パッケージ全体でレンダリング結果が一致する。
/// 着色は環境の ``MarkdownEditorTheme`` から取得する。既定はシステムの意味色で
/// ライト/ダークに自動追従し、外部のデザインシステムを必要としない。
public struct MarkdownEditor: View {

    @Binding private var text: String
    private let baseFontSize: CGFloat
    private let inputRules: InputRuleProcessor
    private let livePreview: Bool
    private let toolbarItems: [MarkdownEditorToolbarItem]

    /// 呼び出し側が渡さなかった場合に使う内部コントローラ。
    @StateObject private var ownedController = MarkdownEditorController()
    private let injectedController: MarkdownEditorController?

    /// 呼び出し側が `mode` を持たない場合に使う内部状態。
    @State private var ownedMode: MarkdownEditorMode
    private let injectedMode: Binding<MarkdownEditorMode>?

    @Environment(\.markdownEditorTheme) private var environmentTheme

    private var controller: MarkdownEditorController { injectedController ?? ownedController }
    private var mode: Binding<MarkdownEditorMode> { injectedMode ?? $ownedMode }

    /// `text` にバインドした Markdown エディタを作成する。
    ///
    /// モードはエディタ内部で保持する。外から観測・制御したい場合は
    /// ``init(text:mode:baseFontSize:livePreview:inputRules:toolbar:controller:)`` を使う。
    ///
    /// - Parameters:
    ///   - text: 編集対象の Markdown ソース。
    ///   - initialMode: 初期表示モード。
    ///   - baseFontSize: エディタのベースフォントサイズ。
    ///   - livePreview: `true` のとき、編集面でインラインマーカーを非表示にしてソースをインプレースレンダリングする
    ///     （Notion スタイル）。キャレット行ではマーカーが表示される。プレーン `.md` テキストが唯一の正を維持する。
    ///   - inputRules: オートフォーマットルール（既定は標準セット）。
    ///   - toolbar: フォーマットツールバーの項目。空配列を渡すとツールバーを表示しない。
    ///   - controller: プログラムからコマンドを送るためのコントローラ。省略すると内部で生成する。
    public init(
        text: Binding<String>,
        initialMode: MarkdownEditorMode = .edit,
        baseFontSize: CGFloat = 16,
        livePreview: Bool = false,
        inputRules: InputRuleProcessor = .standard,
        toolbar: [MarkdownEditorToolbarItem] = .standard,
        controller: MarkdownEditorController? = nil
    ) {
        self._text = text
        self._ownedMode = State(initialValue: initialMode)
        self.injectedMode = nil
        self.baseFontSize = baseFontSize
        self.livePreview = livePreview
        self.inputRules = inputRules
        self.toolbarItems = toolbar
        self.injectedController = controller
    }

    /// モードを外部の `Binding` で制御する Markdown エディタを作成する。
    ///
    /// ツールバーやモード切替を自前の UI に置きたい場合に使う。
    ///
    /// - Parameters:
    ///   - text: 編集対象の Markdown ソース。
    ///   - mode: 表示モード。エディタ内のピッカーと双方向に同期する。
    ///   - baseFontSize: エディタのベースフォントサイズ。
    ///   - livePreview: ライブプレビューを有効にするか。
    ///   - inputRules: オートフォーマットルール（既定は標準セット）。
    ///   - toolbar: フォーマットツールバーの項目。空配列を渡すとツールバーを表示しない。
    ///   - controller: プログラムからコマンドを送るためのコントローラ。省略すると内部で生成する。
    public init(
        text: Binding<String>,
        mode: Binding<MarkdownEditorMode>,
        baseFontSize: CGFloat = 16,
        livePreview: Bool = false,
        inputRules: InputRuleProcessor = .standard,
        toolbar: [MarkdownEditorToolbarItem] = .standard,
        controller: MarkdownEditorController? = nil
    ) {
        self._text = text
        self._ownedMode = State(initialValue: mode.wrappedValue)
        self.injectedMode = mode
        self.baseFontSize = baseFontSize
        self.livePreview = livePreview
        self.inputRules = inputRules
        self.toolbarItems = toolbar
        self.injectedController = controller
    }

    private var theme: MarkdownEditorTheme {
        var resolved = environmentTheme
        resolved.baseFontSize = baseFontSize
        return resolved
    }

    private var availableModes: [MarkdownEditorMode] {
        #if os(macOS)
        [.edit, .split, .preview]
        #else
        [.edit, .preview]
        #endif
    }

    public var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            content
        }
        .background(Color(theme.backgroundColor))
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 0) {
            // Mode switcher row. The control fills the width so its segments are
            // equal (each segment is maxWidth: .infinity internally); a content-
            // hugging control would size segments to their labels and look uneven.
            Picker("", selection: mode) {
                ForEach(availableModes, id: \.self) { candidate in
                    Text(candidate.displayName).tag(candidate)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .frame(maxWidth: 420)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 8)
            .padding(.top, 6)

            // Formatting toolbar row. プレビュー専用モードではソーステキストビュー自体が
            // マウントされていないので、フォーマットコマンドは適用先を持たない。
            if mode.wrappedValue != .preview && !toolbarItems.isEmpty {
                MarkdownFormattingToolbar(controller: controller, items: toolbarItems)
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        switch mode.wrappedValue {
        case .edit:
            editor
        case .preview:
            preview
        case .split:
            HStack(spacing: 0) {
                editor
                Divider()
                preview
            }
        }
    }

    private var editor: some View {
        MarkdownSourceTextView(
            text: $text,
            theme: theme,
            inputRules: inputRules,
            livePreview: livePreview,
            onMakeTextView: { controller.bind($0) }
        )
    }

    private var preview: some View {
        ScrollView {
            MarkdownView(text)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
        }
    }
}

#Preview {
    struct PreviewHost: View {
        @State private var text = """
        # Markdown Editor

        Type **bold**, *italic*, and `code`.

        - one
        - two

        > A quote.
        """
        var body: some View {
            MarkdownEditor(text: $text)
        }
    }
    return PreviewHost()
}
