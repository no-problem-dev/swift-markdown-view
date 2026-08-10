import SwiftMarkdownView
import Foundation

/// One navigable entry in the catalog.
struct MarkdownCatalogItem: Identifiable, Hashable, Sendable {

    /// A fresh identifier minted at initialization, not derived from the other properties.
    ///
    /// Because equality and hashing include it, two items describing the same element
    /// compare unequal. Hold on to an instance rather than rebuilding one to match it.
    let id: UUID

    /// The label shown in list rows, and the key the router matches against.
    let name: String

    /// The name of the SF Symbol shown alongside the label.
    let icon: String

    /// One-line summary shown under the label.
    let description: String

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
