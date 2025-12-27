import Testing
import SwiftUI
@testable import SwiftMarkdownView

/// Snapshot tests for code blocks with syntax highlighting.
///
/// Tests rendering of various programming language code blocks.
@Suite("Code Block Snapshots")
@MainActor
struct CodeBlockSnapshotTests {

    // MARK: - Plain Code

    @Test
    func plain() {
        let view = MarkdownView("""
        ```
        Some plain code
        without syntax highlighting
        ```
        """)
        SnapshotTestHelper.assertSnapshot(of: view)
    }

    // MARK: - Swift

    @Test
    func swift() {
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
        SnapshotTestHelper.assertSnapshot(of: view)
    }

    // MARK: - TypeScript

    @Test
    func typescript() {
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
        SnapshotTestHelper.assertSnapshot(of: view)
    }

    // MARK: - Python

    @Test
    func python() {
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
        SnapshotTestHelper.assertSnapshot(of: view)
    }

    // MARK: - Go

    @Test
    func go() {
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
        SnapshotTestHelper.assertSnapshot(of: view)
    }

    // MARK: - Rust

    @Test
    func rust() {
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
        SnapshotTestHelper.assertSnapshot(of: view)
    }

    // MARK: - Ruby

    @Test
    func ruby() {
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
        SnapshotTestHelper.assertSnapshot(of: view)
    }

    // MARK: - SQL

    @Test
    func sql() {
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
        SnapshotTestHelper.assertSnapshot(of: view)
    }

    // MARK: - JSON

    @Test
    func json() {
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
        SnapshotTestHelper.assertSnapshot(of: view)
    }

    // MARK: - YAML

    @Test
    func yaml() {
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
        SnapshotTestHelper.assertSnapshot(of: view)
    }

    // MARK: - Shell

    @Test
    func shell() {
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
        SnapshotTestHelper.assertSnapshot(of: view)
    }
}
