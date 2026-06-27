import Foundation

/// A single item in the Markdown catalog.
///
/// Represents a navigable entry in the catalog with a name,
/// icon, and description.
struct MarkdownCatalogItem: Identifiable, Hashable, Sendable {

    /// Unique identifier for this item.
    let id: UUID

    /// The display name of this item.
    let name: String

    /// The SF Symbol icon for this item.
    let icon: String

    /// A brief description of this item.
    let description: String

    /// Creates a new catalog item.
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
