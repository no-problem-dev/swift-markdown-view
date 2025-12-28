//
//  MarkdownPlaygroundApp.swift
//  MarkdownPlayground
//
//  Created by 谷口恭一 on 2025/12/27.
//

import SwiftUI
import SwiftMarkdownView
import DesignSystem

@main
struct MarkdownPlaygroundApp: App {
    @State private var themeProvider = ThemeProvider()

    var body: some Scene {
        WindowGroup {
            MarkdownCatalogView()
                .theme(themeProvider)
        }
    }
}
