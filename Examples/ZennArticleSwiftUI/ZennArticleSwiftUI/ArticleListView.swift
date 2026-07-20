import SwiftUI

struct ArticleListView: View {
    let articles: [Article]

    var body: some View {
        List(articles) { article in
            NavigationLink(value: article) {
                ArticleRow(article: article)
            }
        }
        .listStyle(.plain)
        .navigationTitle("Zenn Articles")
    }
}

private struct ArticleRow: View {
    let article: Article

    var body: some View {
        HStack(spacing: 12) {
            Text(article.emoji)
                .font(.largeTitle)
                .frame(width: 50, height: 50)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 4) {
                Text(article.title)
                    .font(.headline)
                    .lineLimit(2)

                HStack(spacing: 4) {
                    ForEach(article.topics.prefix(3), id: \.self) { topic in
                        Text(topic)
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.1))
                            .foregroundStyle(.blue)
                            .clipShape(Capsule())
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}
