import SwiftUI
import SwiftMarkdownView

struct ArticleDetailView: View {
    let article: Article

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
                MarkdownView(article.content)
                    .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
    }
}
