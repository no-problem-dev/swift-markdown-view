import Foundation

struct Article: Identifiable, Hashable {
    let id: String
    let title: String
    let emoji: String
    let topics: [String]
    let content: String

    var filename: String { id }
}

extension Article {
    /// Parses Zenn-style frontmatter from markdown content.
    static func parse(from markdown: String, id: String) -> Article {
        var title = "Untitled"
        var emoji = "📝"
        var topics: [String] = []
        var content = markdown

        // Parse YAML frontmatter
        if markdown.hasPrefix("---") {
            let lines = markdown.components(separatedBy: "\n")
            var frontmatterEnd = 0

            for (index, line) in lines.dropFirst().enumerated() {
                if line == "---" {
                    frontmatterEnd = index + 2
                    break
                }

                if line.hasPrefix("title:") {
                    title = line
                        .replacingOccurrences(of: "title:", with: "")
                        .trimmingCharacters(in: .whitespaces)
                        .trimmingCharacters(in: CharacterSet(charactersIn: "\""))
                }

                if line.hasPrefix("emoji:") {
                    emoji = line
                        .replacingOccurrences(of: "emoji:", with: "")
                        .trimmingCharacters(in: .whitespaces)
                        .trimmingCharacters(in: CharacterSet(charactersIn: "\""))
                }

                if line.hasPrefix("topics:") {
                    let topicsString = line
                        .replacingOccurrences(of: "topics:", with: "")
                        .trimmingCharacters(in: .whitespaces)

                    // Parse array format: ["swift", "swiftui"]
                    if topicsString.hasPrefix("[") {
                        topics = topicsString
                            .trimmingCharacters(in: CharacterSet(charactersIn: "[]"))
                            .components(separatedBy: ",")
                            .map { $0.trimmingCharacters(in: .whitespaces).trimmingCharacters(in: CharacterSet(charactersIn: "\"")) }
                    }
                }
            }

            // Extract content after frontmatter
            if frontmatterEnd > 0 && frontmatterEnd < lines.count {
                content = lines[frontmatterEnd...].joined(separator: "\n")
            }
        }

        return Article(
            id: id,
            title: title,
            emoji: emoji,
            topics: topics,
            content: content
        )
    }
}
