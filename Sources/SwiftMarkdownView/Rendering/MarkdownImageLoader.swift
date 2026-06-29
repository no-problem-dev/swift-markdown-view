#if os(iOS) || os(macOS)
import Foundation
import MarkdownAttributedKit

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// Markdown 画像ソースをプラットフォーム画像に読み込む。HTTP(S) はリモート、
/// それ以外はローカルファイルパスまたはバンドルリソース名として扱う。
enum MarkdownImageLoader {

    static func load(_ source: String) async -> PlatformImage? {
        if let url = URL(string: source), let scheme = url.scheme?.lowercased() {
            if scheme == "http" || scheme == "https" {
                guard let (data, _) = try? await URLSession.shared.data(from: url) else { return nil }
                return PlatformImage(data: data)
            }
            if scheme == "file" {
                return PlatformImage(contentsOfFile: url.path)
            }
        }
        if let image = PlatformImage(contentsOfFile: source) { return image }
        #if canImport(UIKit)
        return UIImage(named: source)
        #elseif canImport(AppKit)
        return NSImage(named: source)
        #endif
    }
}
#endif
