import Testing
import SwiftUI
import SnapshotTesting
@testable import SwiftMarkdownView

/// Snapshot tests for visual validation of MarkdownView rendering.
///
/// These tests capture the rendered output and compare against stored reference images.
/// Run with `swift test` - first run will record reference snapshots.
@Suite("Snapshot Tests")
@MainActor
struct SnapshotTests {

    // MARK: - Configuration

    /// Set to true to record new reference snapshots
    private let isRecording = false

    /// Standard size for snapshot testing
    private let snapshotSize = CGSize(width: 400, height: 600)

    // MARK: - Helper

    private func snapshotView<V: View>(_ view: V, named name: String) {
        let hostingController = NSHostingController(
            rootView: view
                .frame(width: snapshotSize.width)
                .padding()
                .background(Color.white)
        )

        hostingController.view.frame = CGRect(
            origin: .zero,
            size: CGSize(width: snapshotSize.width + 32, height: snapshotSize.height)
        )

        assertSnapshot(
            of: hostingController,
            as: .image,
            named: name,
            record: isRecording
        )
    }

    // MARK: - Block Element Snapshots

    @Test("Snapshot: Plain paragraph")
    func snapshotParagraph() {
        let view = MarkdownView("This is a simple paragraph of text.")
        snapshotView(view, named: "paragraph")
    }

    @Test("Snapshot: Heading levels")
    func snapshotHeadings() {
        let view = MarkdownView("""
        # Heading 1
        ## Heading 2
        ### Heading 3
        #### Heading 4
        ##### Heading 5
        ###### Heading 6
        """)
        snapshotView(view, named: "headings")
    }

    @Test("Snapshot: Code block with Swift syntax highlighting")
    func snapshotCodeBlock() {
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
        snapshotView(view, named: "code-block-swift")
    }

    @Test("Snapshot: Code block with TypeScript syntax highlighting")
    func snapshotCodeBlockTypeScript() {
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
        snapshotView(view, named: "code-block-typescript")
    }

    @Test("Snapshot: Code block without language")
    func snapshotCodeBlockNoLanguage() {
        let view = MarkdownView("""
        ```
        Some plain code
        without syntax highlighting
        ```
        """)
        snapshotView(view, named: "code-block-plain")
    }

    @Test("Snapshot: Unordered list")
    func snapshotUnorderedList() {
        let view = MarkdownView("""
        - First item
        - Second item
        - Third item
        """)
        snapshotView(view, named: "unordered-list")
    }

    @Test("Snapshot: Ordered list")
    func snapshotOrderedList() {
        let view = MarkdownView("""
        1. First item
        2. Second item
        3. Third item
        """)
        snapshotView(view, named: "ordered-list")
    }

    @Test("Snapshot: Blockquote")
    func snapshotBlockquote() {
        let view = MarkdownView("""
        > This is a blockquote.
        > It can span multiple lines.
        """)
        snapshotView(view, named: "blockquote")
    }

    @Test("Snapshot: Table")
    func snapshotTable() {
        let view = MarkdownView("""
        | Feature | Status | Priority |
        |:--------|:------:|--------:|
        | Auth    | ✅     | High    |
        | API     | 🔄     | Medium  |
        | Tests   | ❌     | Low     |
        """)
        snapshotView(view, named: "table")
    }

    @Test("Snapshot: Task list")
    func snapshotTaskList() {
        let view = MarkdownView("""
        - [x] Complete setup
        - [x] Write documentation
        - [ ] Add tests
        - [ ] Deploy to production
        """)
        snapshotView(view, named: "task-list")
    }

    @Test("Snapshot: Image placeholder")
    func snapshotImagePlaceholder() {
        // Using a non-http URL to show fallback rendering
        let view = MarkdownView("""
        Here is an image:

        ![Sample Image](./local/image.png)

        This tests the fallback placeholder view.
        """)
        snapshotView(view, named: "image-placeholder")
    }

    @Test("Snapshot: Local bundle image")
    func snapshotLocalBundleImage() {
        // Test with bundled test image
        guard let imageURL = Bundle.module.url(
            forResource: "test-profile-image",
            withExtension: "jpg",
            subdirectory: "Resources"
        ) else {
            Issue.record("Test image not found in bundle")
            return
        }

        let view = MarkdownView("""
        # Profile

        ![\(imageURL.lastPathComponent)](\(imageURL.absoluteString))

        This is a test with a local bundled image.
        """)
        snapshotView(view, named: "local-bundle-image")
    }

    // MARK: - Inline Element Snapshots

    @Test("Snapshot: Emphasis and strong")
    func snapshotEmphasisStrong() {
        let view = MarkdownView("""
        This text has *emphasis* and **strong** formatting.
        You can also combine ***both***.
        """)
        snapshotView(view, named: "emphasis-strong")
    }

    @Test("Snapshot: Inline code")
    func snapshotInlineCode() {
        let view = MarkdownView("""
        Use the `let` keyword to declare a constant.
        """)
        snapshotView(view, named: "inline-code")
    }

    @Test("Snapshot: Links")
    func snapshotLinks() {
        let view = MarkdownView("""
        Visit [Apple](https://apple.com) for more info.
        """)
        snapshotView(view, named: "links")
    }

    // MARK: - Additional Language Snapshots

    @Test("Snapshot: Code block with Python syntax highlighting")
    func snapshotCodeBlockPython() {
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
        snapshotView(view, named: "code-block-python")
    }

    @Test("Snapshot: Code block with Go syntax highlighting")
    func snapshotCodeBlockGo() {
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
        snapshotView(view, named: "code-block-go")
    }

    @Test("Snapshot: Code block with Rust syntax highlighting")
    func snapshotCodeBlockRust() {
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
        snapshotView(view, named: "code-block-rust")
    }

    @Test("Snapshot: Code block with Ruby syntax highlighting")
    func snapshotCodeBlockRuby() {
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
        snapshotView(view, named: "code-block-ruby")
    }

    @Test("Snapshot: Code block with SQL syntax highlighting")
    func snapshotCodeBlockSQL() {
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
        snapshotView(view, named: "code-block-sql")
    }

    @Test("Snapshot: Code block with JSON syntax highlighting")
    func snapshotCodeBlockJSON() {
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
        snapshotView(view, named: "code-block-json")
    }

    @Test("Snapshot: Code block with YAML syntax highlighting")
    func snapshotCodeBlockYAML() {
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
        snapshotView(view, named: "code-block-yaml")
    }

    @Test("Snapshot: Code block with Shell syntax highlighting")
    func snapshotCodeBlockShell() {
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
        snapshotView(view, named: "code-block-shell")
    }

    // MARK: - Complex Document Snapshots

    @Test("Snapshot: AI response style document")
    func snapshotAIResponse() {
        let view = MarkdownView("""
        # API Response

        Here's how to implement the feature:

        ## Step 1: Create the Model

        ```swift
        struct User: Codable {
            let id: UUID
            let name: String
        }
        ```

        ## Step 2: Implement the Service

        The service should:

        - Handle authentication
        - Manage API calls
        - Cache responses

        > **Note**: Make sure to handle errors appropriately.

        For more details, see the [documentation](https://example.com).
        """)
        snapshotView(view, named: "ai-response")
    }
}
