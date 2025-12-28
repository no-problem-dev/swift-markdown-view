import Foundation

/// A single item in the Markdown catalog.
///
/// Represents a navigable entry in the catalog with a name,
/// icon, and description.
public struct MarkdownCatalogItem: Identifiable, Hashable, Sendable {

    /// Unique identifier for this item.
    public let id: UUID

    /// The display name of this item.
    public let name: String

    /// The SF Symbol icon for this item.
    public let icon: String

    /// A brief description of this item.
    public let description: String

    /// Creates a new catalog item.
    ///
    /// - Parameters:
    ///   - name: The display name.
    ///   - icon: The SF Symbol icon name.
    ///   - description: A brief description.
    public init(
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
