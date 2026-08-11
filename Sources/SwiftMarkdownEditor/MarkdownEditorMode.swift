import Foundation

/// How the editor presents its content.
public enum MarkdownEditorMode: String, CaseIterable, Hashable, Sendable {
    /// Source editing only.
    case edit
    /// The rendered preview only. No source text view is mounted, so the
    /// formatting toolbar is hidden along with its keyboard shortcuts.
    case preview
    /// Source and rendered preview side by side, suited to macOS and wide layouts.
    ///
    /// The editor's built-in mode picker offers this case on macOS only, but
    /// selecting it through a `mode` binding lays out the split on iOS too.
    case split

    /// A short label for the built-in mode picker.
    ///
    /// The labels are English literals and are not localized. Drive the editor
    /// with a `mode` binding and build your own switcher to show other languages.
    public var displayName: String {
        switch self {
        case .edit: return "Edit"
        case .preview: return "Preview"
        case .split: return "Split"
        }
    }
}
