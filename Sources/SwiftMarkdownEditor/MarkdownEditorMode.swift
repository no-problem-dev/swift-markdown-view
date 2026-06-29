import Foundation

/// エディタのコンテンツ表示方式。
public enum MarkdownEditorMode: String, CaseIterable, Hashable, Sendable {
    /// ソース編集のみ。
    case edit
    /// レンダリングプレビューのみ。
    case preview
    /// ソースとプレビューを並列表示（macOS や幅広レイアウトに最適）。
    case split

    /// モードスイッチャー用の短いラベル。
    public var displayName: String {
        switch self {
        case .edit: return "編集"
        case .preview: return "プレビュー"
        case .split: return "分割"
        }
    }
}
