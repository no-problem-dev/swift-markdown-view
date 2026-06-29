import SwiftUI

/// シンタックスハイライト処理の状態。
///
/// 非同期シンタックスハイライトを実行するビューが処理の現在状態を追跡するために使用する。
public enum HighlightState: Sendable {
    /// ハイライトがまだ要求されていない状態。
    case idle

    /// ハイライト処理中。
    case loading

    /// ハイライトが正常に完了した状態。
    case success(AttributedString)

    /// ハイライトがエラーで失敗した状態。
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
            // 状態比較の目的ではエラーを等しいとみなす
            return true
        default:
            return false
        }
    }
}

// MARK: - Convenience Properties

extension HighlightState {
    /// 現在ローディング中かどうか。
    public var isLoading: Bool {
        if case .loading = self { return true }
        return false
    }

    /// ハイライト結果（利用可能な場合）。
    public var result: AttributedString? {
        if case let .success(result) = self { return result }
        return nil
    }

    /// ハイライトが失敗した場合のエラー。
    public var error: (any Error)? {
        if case let .failure(error) = self { return error }
        return nil
    }
}
