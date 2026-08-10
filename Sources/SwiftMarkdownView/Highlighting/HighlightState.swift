import SwiftUI

/// The state of an asynchronous syntax-highlighting operation.
///
/// Views that highlight code off the main actor use this to track where the work stands.
public enum HighlightState: Sendable {
    /// Highlighting has not been requested yet.
    case idle

    /// Highlighting is under way.
    case loading

    /// Highlighting finished and produced styled text.
    case success(AttributedString)

    /// Highlighting failed.
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
            // Any two failures compare equal; the underlying errors are not compared.
            return true
        default:
            return false
        }
    }
}

// MARK: - Convenience Properties

extension HighlightState {
    public var isLoading: Bool {
        if case .loading = self { return true }
        return false
    }

    /// The styled text, available only once highlighting has succeeded.
    public var result: AttributedString? {
        if case let .success(result) = self { return result }
        return nil
    }

    public var error: (any Error)? {
        if case let .failure(error) = self { return error }
        return nil
    }
}
