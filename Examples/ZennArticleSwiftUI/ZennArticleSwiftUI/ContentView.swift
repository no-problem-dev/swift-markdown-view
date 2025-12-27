import SwiftUI

struct ContentView: View {
    @State private var articles: [Article] = []

    var body: some View {
        NavigationStack {
            ArticleListView(articles: articles)
                .navigationDestination(for: Article.self) { article in
                    ArticleDetailView(article: article)
                }
        }
        .task {
            articles = loadArticles()
        }
    }

    private func loadArticles() -> [Article] {
        let articleFiles = [
            "swiftui-architecture",
            "swiftui-environment-generic",
            "llmcodable-introduction",
        ]

        return articleFiles.compactMap { filename in
            guard let url = Bundle.main.url(forResource: filename, withExtension: "md"),
                  let content = try? String(contentsOf: url, encoding: .utf8) else {
                return nil
            }
            return Article.parse(from: content, id: filename)
        }
    }
}

#Preview {
    ContentView()
}
