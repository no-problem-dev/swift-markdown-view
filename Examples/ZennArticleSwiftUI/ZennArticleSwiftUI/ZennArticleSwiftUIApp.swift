//
//  ZennArticleSwiftUIApp.swift
//  ZennArticleSwiftUI
//
//  Created by 谷口恭一 on 2025/12/27.
//

import SwiftUI
import DesignSystem

@main
struct ZennArticleSwiftUIApp: App {
    @State private var themeProvider = ThemeProvider()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .theme(themeProvider)
        }
    }
}
