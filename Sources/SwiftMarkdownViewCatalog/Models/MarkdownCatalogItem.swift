import SwiftMarkdownView
import Foundation

/// Markdown カタログの単一アイテム。
///
/// 名前・アイコン・説明を持つ、カタログ内のナビゲーション可能なエントリー。
struct MarkdownCatalogItem: Identifiable, Hashable, Sendable {

    /// このアイテムの一意識別子。
    let id: UUID

    /// このアイテムの表示名。
    let name: String

    /// このアイテムの SF Symbol アイコン名。
    let icon: String

    /// このアイテムの概要説明。
    let description: String

    /// カタログアイテムを作成する。
    init(
        name: String,
        icon: String,
        description: String
    ) {
        self.id = UUID()
        self.name = name
        self.icon = icon
        self.description = description
    }
}
