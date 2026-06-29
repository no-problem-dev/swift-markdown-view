import Foundation
import SwiftMarkdownEditorCore

/// 入力ルールが通常の挿入の代わりに適用する変換。
public struct RuleTransform: Equatable, Sendable {
    /// ユーザーの生の挿入の代わりに適用する変更。
    public var change: TextChange
    /// 結果の状態のセレクション。
    public var selection: Selection
    /// 結果の undo エントリを隣接エントリと合成してよいか。
    /// ルール編集は通常個別の undo ステップのため、デフォルトは `false`。
    public var allowCoalescing: Bool

    public init(change: TextChange, selection: Selection, allowCoalescing: Bool = false) {
        self.change = change
        self.selection = selection
        self.allowCoalescing = allowCoalescing
    }
}

/// ユーザーのテキスト入力を書き換えるルール — Markdown オートフォーマット。
///
/// ProseMirror の input rules をモデルにしている。状態と `range` に挿入しようとしているテキストを受け取り、
/// ルールは代わりに適用する ``RuleTransform`` を返せる。
/// ルールは入力の純粋関数のため、オートフォーマット層全体をテキストビューなしでユニットテストできる。
public protocol InputRule: Sendable {
    /// - Parameters:
    ///   - state: 挿入 *前* の状態。
    ///   - text: ユーザーが挿入するテキスト（タイプした文字・改行・ペースト）。
    ///   - range: 挿入が置換する範囲（キャレット位置では空）。
    /// - Returns: 代わりに適用する変換。このルールで処理しない場合は `nil`。
    func transform(state: EditorState, inserting text: String, replacing range: TextSpan) -> RuleTransform?
}
