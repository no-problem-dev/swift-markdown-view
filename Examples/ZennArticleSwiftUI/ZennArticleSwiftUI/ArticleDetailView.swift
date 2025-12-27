import SwiftUI
import SwiftMarkdownView
import SwiftMarkdownViewHighlightJS

struct ArticleDetailView: View {
    let article: Article
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text(article.emoji)
                        .font(.system(size: 60))

                    Text(article.title)
                        .font(.title)
                        .fontWeight(.bold)

                    HStack(spacing: 6) {
                        ForEach(article.topics, id: \.self) { topic in
                            Text(topic)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.blue.opacity(0.1))
                                .foregroundStyle(.blue)
                                .clipShape(Capsule())
                        }
                    }
                }
                .padding(.horizontal)

                Divider()

                // Markdown content
                // Note: Using a11y/xcode themes for best visibility
                // a11y light has better contrast than xcode light
                MarkdownView(article.content)
                    .syntaxHighlighter(
                        colorScheme == .dark
                            ? HighlightJSSyntaxHighlighter.xcodeDark
                            : HighlightJSSyntaxHighlighter.a11yLight
                    )
                    .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
    }
}
