import SwiftUI

/// The state of a syntax highlighting operation.
///
/// Used by views that perform asynchronous syntax highlighting
/// to track the current state of the operation.
public enum HighlightState: Sendable {
    /// No highlighting has been requested yet.
    case idle

    /// Highlighting is in progress.
    case loading

    /// Highlighting completed successfully.
    case success(AttributedString)

    /// Highlighting failed with an error.
    case failure(any Error)
}

// MARK: - Equatable

extension HighlightState: Equatable {
    public static func == (lhs: HighlightState, rhs: HighlightState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle):
            return true
        case (.loading, .loading):
            return true
        case let (.success(lhsResult), .success(rhsResult)):
            return lhsResult == rhsResult
        case (.failure, .failure):
            // Errors are considered equal for state comparison purposes
            return true
        default:
            return false
        }
    }
}

// MARK: - Convenience Properties

extension HighlightState {
    /// Whether the state is currently loading.
    public var isLoading: Bool {
        if case .loading = self { return true }
        return false
    }

    /// The highlighted result if available.
    public var result: AttributedString? {
        if case let .success(result) = self { return result }
        return nil
    }

    /// The error if highlighting failed.
    public var error: (any Error)? {
        if case let .failure(error) = self { return error }
        return nil
    }
}
