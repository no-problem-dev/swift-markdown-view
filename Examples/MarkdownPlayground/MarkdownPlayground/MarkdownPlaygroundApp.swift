//
//  MarkdownPlaygroundApp.swift
//  MarkdownPlayground
//
//  Created by 谷口恭一 on 2025/12/27.
//

import SwiftUI
import SwiftMarkdownView
import SwiftMarkdownViewHighlightJS
import DesignSystem

@main
struct MarkdownPlaygroundApp: App {
    @State private var themeProvider = ThemeProvider()

    var body: some Scene {
        WindowGroup {
            TabView {
                MarkdownCatalogView()
                    .tabItem { Label("カタログ", systemImage: "list.bullet.rectangle") }

                NavigationStack {
                    SelectionShowcaseView()
                }
                .tabItem { Label("選択・コピー", systemImage: "selection.pin.in.out") }
            }
            .theme(themeProvider)
            .adaptiveSyntaxHighlighting()
        }
    }
}
