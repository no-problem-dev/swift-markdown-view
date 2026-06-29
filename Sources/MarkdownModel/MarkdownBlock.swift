import Foundation

/// Markdown ドキュメントのブロックレベル要素。
///
/// 段落・見出し・コードブロック・リストなど、ドキュメントの最上位構造要素を表す。
public enum MarkdownBlock: Sendable, Equatable {

    /// インラインコンテンツを含む段落。
    case paragraph([MarkdownInline])

    /// レベル（1–6）とインラインコンテンツを持つ見出し。
    case heading(level: Int, content: [MarkdownInline])

    /// フェンスまたはインデント形式のコードブロック。
    case codeBlock(language: String?, code: String)

    /// ネストしたブロックを含む aside（コールアウト/アドモニション）。
    ///
    /// ブロッククォートにオプションの種類タグを付けて解釈する:
    /// - `> Note: This is a note` → `.aside(kind: .note, content: ...)`
    /// - `> Warning: Be careful` → `.aside(kind: .warning, content: ...)`
    /// - `> Regular quote` → `.aside(kind: .note, content: ...)` (デフォルト)
    case aside(kind: AsideKind, content: [MarkdownBlock])

    /// 順序なし（箇条書き）リスト。
    case unorderedList([ListItem])

    /// 順序付き（番号付き）リスト。
    case orderedList(start: Int, items: [ListItem])

    /// テーマティックブレーク（水平線）。
    case thematicBreak

    /// テーブル（GFM 拡張）。
    case table(TableData)

    /// Mermaid ダイアグラムブロック。
    ///
    /// `mermaid` を言語とするフェンスコードブロックで、Mermaid.js で視覚化する。
    case mermaid(String)

    /// LaTeX ソース（デリミターなし）を含むディスプレイ数式ブロック。
    ///
    /// `$$...$$`、`\[...\]`、```` ```math ```` フェンスで生成する。レンダリングは環境の ``MathRenderer`` に委譲する。
    case math(String)
}

// MARK: - Aside Types

/// aside（コールアウト/アドモニション）の種類。
///
/// ブロッククォートの先頭に置いた種類タグから解釈する。
/// 例: `> Note: This is important` は `.note` の aside になる。
///
/// swift-markdown の `Aside.Kind` をベースに、一般的なドキュメントコールアウト種類を含む。
public enum AsideKind: Sendable, Equatable, Hashable {
    // Common callouts
    case note
    case tip
    case important
    case warning
    case experiment

    // Additional callouts
    case attention
    case author
    case authors
    case bug
    case complexity
    case copyright
    case date
    case invariant
    case mutatingVariant
    case nonMutatingVariant
    case postcondition
    case precondition
    case remark
    case requires
    case since
    case todo
    case version
    case `throws`
    case seeAlso

    /// ユーザー定義のカスタム aside 種類。
    case custom(String)

    /// aside 種類の人間が読める表示名。
    public var displayName: String {
        switch self {
        case .note: return "Note"
        case .tip: return "Tip"
        case .important: return "Important"
        case .warning: return "Warning"
        case .experiment: return "Experiment"
        case .attention: return "Attention"
        case .author: return "Author"
        case .authors: return "Authors"
        case .bug: return "Bug"
        case .complexity: return "Complexity"
        case .copyright: return "Copyright"
        case .date: return "Date"
        case .invariant: return "Invariant"
        case .mutatingVariant: return "Mutating Variant"
        case .nonMutatingVariant: return "Non-Mutating Variant"
        case .postcondition: return "Postcondition"
        case .precondition: return "Precondition"
        case .remark: return "Remark"
        case .requires: return "Requires"
        case .since: return "Since"
        case .todo: return "To Do"
        case .version: return "Version"
        case .throws: return "Throws"
        case .seeAlso: return "See Also"
        case .custom(let name): return name
        }
    }

    /// 文字列から aside の種類を生成する。
    ///
    /// 大文字小文字を区別しない。
    ///
    /// - Parameter rawValue: ブロッククォートの文字列タグ。
    public init(rawValue: String) {
        switch rawValue.lowercased() {
        case "note": self = .note
        case "tip": self = .tip
        case "important": self = .important
        case "warning": self = .warning
        case "experiment": self = .experiment
        case "attention": self = .attention
        case "author": self = .author
        case "authors": self = .authors
        case "bug": self = .bug
        case "complexity": self = .complexity
        case "copyright": self = .copyright
        case "date": self = .date
        case "invariant": self = .invariant
        case "mutatingvariant": self = .mutatingVariant
        case "nonmutatingvariant": self = .nonMutatingVariant
        case "postcondition": self = .postcondition
        case "precondition": self = .precondition
        case "remark": self = .remark
        case "requires": self = .requires
        case "since": self = .since
        case "todo": self = .todo
        case "version": self = .version
        case "throws": self = .throws
        case "seealso": self = .seeAlso
        default: self = .custom(rawValue)
        }
    }
}

// MARK: - Table Types

/// テーブル全体の構造。
public struct TableData: Sendable, Equatable {

    /// テーブルのヘッダー行。
    public let headerRow: TableRow

    /// テーブルのボディ行。
    public let bodyRows: [TableRow]

    /// 各列のアライメント。
    public let columnAlignments: [TableAlignment]

    public init(
        headerRow: TableRow,
        bodyRows: [TableRow],
        columnAlignments: [TableAlignment]
    ) {
        self.headerRow = headerRow
        self.bodyRows = bodyRows
        self.columnAlignments = columnAlignments
    }
}

/// テーブルの1行。
public struct TableRow: Sendable, Equatable {

    /// この行のセル群。
    public let cells: [[MarkdownInline]]

    public init(cells: [[MarkdownInline]]) {
        self.cells = cells
    }
}

/// テーブルの列アライメント。
public enum TableAlignment: Sendable, Equatable {
    case left
    case center
    case right
    case none
}

/// ネストしたブロックを含むリスト項目。
public struct ListItem: Sendable, Equatable {

    /// この項目に含まれるブロック群。
    public let blocks: [MarkdownBlock]

    /// タスクリストのチェック状態。`nil` はタスクリスト項目でないことを示す。
    public let isChecked: Bool?

    public init(blocks: [MarkdownBlock], isChecked: Bool? = nil) {
        self.blocks = blocks
        self.isChecked = isChecked
    }
}
