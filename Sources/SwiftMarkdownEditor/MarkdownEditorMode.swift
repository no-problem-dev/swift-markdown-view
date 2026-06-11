import Foundation

/// How the editor presents content.
public enum MarkdownEditorMode: String, CaseIterable, Hashable, Sendable {
    /// Source editing only.
    case edit
    /// Rendered preview only.
    case preview
    /// Side-by-side source + preview (best on macOS / wide layouts).
    case split

    /// A short localized-ish label for the mode switcher.
    public var displayName: String {
        switch self {
        case .edit: return "編集"
        case .preview: return "プレビュー"
        case .split: return "分割"
        }
    }
}
