//
//  MarkdownPlaygroundApp.swift
//  MarkdownPlayground
//
//  Created by 谷口恭一 on 2025/12/27.
//

import SwiftUI
import SwiftMarkdownView
import SwiftMarkdownViewHighlightJS
import SwiftMarkdownViewCatalog

@main
struct MarkdownPlaygroundApp: App {

    var body: some Scene {
        WindowGroup {
            TabView {
                NavigationStack {
                    EditorShowcaseView()
                }
                .tabItem { Label("エディタ", systemImage: "square.and.pencil") }

                MarkdownCatalogView()
                    .tabItem { Label("カタログ", systemImage: "list.bullet.rectangle") }

                NavigationStack {
                    SelectionShowcaseView()
                }
                .tabItem { Label("選択・コピー", systemImage: "selection.pin.in.out") }
            }
            .adaptiveSyntaxHighlighting()
        }
    }
}
