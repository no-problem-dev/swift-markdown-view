import Foundation
import MarkdownModel

/// ある時点のエディタ状態を表す不変値。
///
/// CodeMirror の `EditorState` / ProseMirror の `EditorState` に倣い、
/// ドキュメントテキストと現在のセレクションのみを持つ純粋値型。
/// 編集はインプレース変更ではなく *新しい* `EditorState` を返すため、
/// undo・デコレーションマッピング・将来の協調編集が単一の変換パイプラインで動く。
///
/// パース済み Markdown ドキュメントは `text` からオンデマンドで *導出* される。
/// プレーンな `.md` 文字列が唯一の正であり（リッチツリーを持たない）、
/// フォーマットのラウンドトリップ安全性と diff との相性を保つ。
public struct EditorState: Equatable, Sendable {

    /// ドキュメントのフルテキスト（唯一の正）。
    public private(set) var text: String

    /// `text` 上の現在のセレクション。
    public var selection: Selection

    /// エディタ状態を作成する。
    ///
    /// - Parameters:
    ///   - text: ドキュメントテキスト。
    ///   - selection: セレクション。省略するとテキスト末尾のキャレットになる。
    public init(text: String, selection: Selection? = nil) {
        self.text = text
        self.selection = selection ?? Selection(caret: text.utf16Length)
    }

    /// ドキュメントの長さ（UTF-16 コードユニット数）。
    public var length: Int { text.utf16Length }

    /// `text` を共有パーサでパースし、レンダリング可能なブロック列を返す。
    ///
    /// `SwiftMarkdownView` のパーサを再利用するため、エディタとレンダラーの構造解釈が常に一致する。
    /// オンデマンドで計算されるため、キーストロークごとにレンダリングする場合は結果をキャッシュすること。
    public func parsedContent() -> MarkdownContent {
        MarkdownContent(parsing: text)
    }

    // MARK: - Transforms

    /// `change` を適用した新しい状態を返す。セレクションはマッピングまたは置換される。
    ///
    /// - Parameters:
    ///   - change: 適用する編集。
    ///   - selection: 新しい状態の明示的なセレクション。`nil` のとき、現在のセレクションを
    ///     変更にマッピングする（タイプ入力では挿入テキストの右にキャレットが移動する）。
    public func applying(_ change: TextChange, selection newSelection: Selection? = nil) -> EditorState {
        var next = self
        next.text = change.apply(to: text)
        next.selection = newSelection ?? change.mapSelection(selection)
        return next
    }

    /// `range` を `replacement` で置換し、挿入テキストの後ろにキャレットを置いた新しい状態を返す。
    public func replacing(_ range: TextSpan, with replacement: String) -> EditorState {
        let change = TextChange(range: range, replacement: replacement)
        let caret = range.lowerBound + replacement.utf16Length
        return applying(change, selection: Selection(caret: caret))
    }

    /// 現在のセレクションを `replacement` で置換した新しい状態を返す。
    public func replacingSelection(with replacement: String) -> EditorState {
        replacing(selection.range, with: replacement)
    }
}
