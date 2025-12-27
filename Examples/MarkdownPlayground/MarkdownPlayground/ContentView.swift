//
//  ContentView.swift
//  MarkdownPlayground
//
//  Created by 谷口恭一 on 2025/12/27.
//

import SwiftUI
import SwiftMarkdownView
import DesignSystem

/// Main content view for the Markdown Playground app.
///
/// This view serves as an alternative entry point that can be used
/// for custom implementations or testing purposes.
struct ContentView: View {
    @Environment(\.colorPalette) private var colorPalette

    var body: some View {
        MarkdownCatalogView()
    }
}

#Preview {
    ContentView()
        .theme(ThemeProvider())
}
