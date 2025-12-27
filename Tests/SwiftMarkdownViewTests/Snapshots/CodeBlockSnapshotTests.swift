import Testing
import SwiftUI
@testable import SwiftMarkdownView
import SwiftMarkdownViewHighlightJS

/// Snapshot tests for code blocks with syntax highlighting.
///
/// Tests rendering of various programming language code blocks
/// using HighlightJS-based syntax highlighter for accurate, multi-language support.
@Suite("Code Block Snapshots")
@MainActor
struct CodeBlockSnapshotTests {

    /// Light mode highlighter for white background snapshots.
    /// Note: Using a11y theme instead of xcode because xcode light mode
    /// doesn't set NSColor for plain text, causing visibility issues.
    private let highlighter = HighlightJSSyntaxHighlighter(theme: .a11y, colorMode: .light)

    /// Delay for async syntax highlighting to complete.
    private let highlightDelay: TimeInterval = 1.0

    // MARK: - Plain Code

    @Test
    func plain() async {
        let view = MarkdownView("""
        ```
        Some plain code
        without syntax highlighting
        ```
        """)
        .syntaxHighlighter(highlighter)
        await SnapshotTestHelper.assertSnapshotAsync(of: view, delay: highlightDelay)
    }

    // MARK: - Swift

    @Test
    func swift() async {
        let view = MarkdownView("""
        ```swift
        struct Person {
            let name: String
            let age: Int

            func greet() -> String {
                return "Hello, I'm \\(name)!"
            }
        }
        ```
        """)
        .syntaxHighlighter(highlighter)
        await SnapshotTestHelper.assertSnapshotAsync(of: view, delay: highlightDelay)
    }

    // MARK: - TypeScript

    @Test
    func typescript() async {
        let view = MarkdownView("""
        ```typescript
        interface User {
            name: string;
            age: number;
        }

        const greet = (user: User): string => {
            return `Hello, ${user.name}!`;
        };
        ```
        """)
        .syntaxHighlighter(highlighter)
        await SnapshotTestHelper.assertSnapshotAsync(of: view, delay: highlightDelay)
    }

    // MARK: - Python

    @Test
    func python() async {
        let view = MarkdownView("""
        ```python
        def greet(name: str) -> str:
            # Return a greeting message
            message = f"Hello, {name}!"
            return message

        class Person:
            def __init__(self, name: str, age: int):
                self.name = name
                self.age = age
        ```
        """)
        .syntaxHighlighter(highlighter)
        await SnapshotTestHelper.assertSnapshotAsync(of: view, delay: highlightDelay)
    }

    // MARK: - Go

    @Test
    func go() async {
        let view = MarkdownView("""
        ```go
        package main

        import "fmt"

        func main() {
            // Print greeting
            message := "Hello, Go!"
            fmt.Println(message)
        }
        ```
        """)
        .syntaxHighlighter(highlighter)
        await SnapshotTestHelper.assertSnapshotAsync(of: view, delay: highlightDelay)
    }

    // MARK: - Rust

    @Test
    func rust() async {
        let view = MarkdownView("""
        ```rust
        fn main() {
            // Rust greeting
            let message = "Hello, Rust!";
            println!("{}", message);
        }

        struct Person {
            name: String,
            age: u32,
        }
        ```
        """)
        .syntaxHighlighter(highlighter)
        await SnapshotTestHelper.assertSnapshotAsync(of: view, delay: highlightDelay)
    }

    // MARK: - Ruby

    @Test
    func ruby() async {
        let view = MarkdownView("""
        ```ruby
        class Person
          attr_accessor :name, :age

          def initialize(name, age)
            @name = name
            @age = age
          end

          def greet
            # Return greeting
            puts "Hello, #{@name}!"
          end
        end
        ```
        """)
        .syntaxHighlighter(highlighter)
        await SnapshotTestHelper.assertSnapshotAsync(of: view, delay: highlightDelay)
    }

    // MARK: - SQL

    @Test
    func sql() async {
        let view = MarkdownView("""
        ```sql
        -- Get active users
        SELECT name, email, created_at
        FROM users
        WHERE active = TRUE
        ORDER BY created_at DESC
        LIMIT 10;

        INSERT INTO logs (user_id, action)
        VALUES (1, 'login');
        ```
        """)
        .syntaxHighlighter(highlighter)
        await SnapshotTestHelper.assertSnapshotAsync(of: view, delay: highlightDelay)
    }

    // MARK: - JSON

    @Test
    func json() async {
        let view = MarkdownView("""
        ```json
        {
            "name": "John Doe",
            "age": 30,
            "active": true,
            "email": null,
            "scores": [95, 87, 92]
        }
        ```
        """)
        .syntaxHighlighter(highlighter)
        await SnapshotTestHelper.assertSnapshotAsync(of: view, delay: highlightDelay)
    }

    // MARK: - YAML

    @Test
    func yaml() async {
        let view = MarkdownView("""
        ```yaml
        # Application config
        name: MyApp
        version: 1.0.0
        debug: true

        database:
          host: localhost
          port: 5432
          name: myapp_db
        ```
        """)
        .syntaxHighlighter(highlighter)
        await SnapshotTestHelper.assertSnapshotAsync(of: view, delay: highlightDelay)
    }

    // MARK: - Shell

    @Test
    func shell() async {
        let view = MarkdownView("""
        ```bash
        #!/bin/bash
        # Deploy script

        echo "Starting deployment..."

        if [ -d "./dist" ]; then
            rm -rf ./dist
        fi

        npm run build
        echo "Deployment complete!"
        ```
        """)
        .syntaxHighlighter(highlighter)
        await SnapshotTestHelper.assertSnapshotAsync(of: view, delay: highlightDelay)
    }
}
