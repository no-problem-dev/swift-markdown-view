#if canImport(UIKit)
import UIKit

/// Cross-platform aliases so the TextKit bridge can be written once.
public typealias PlatformColor = UIColor
public typealias PlatformFont = UIFont
public typealias PlatformView = UIView
public typealias PlatformTextView = UITextView

#elseif canImport(AppKit)
import AppKit

public typealias PlatformColor = NSColor
public typealias PlatformFont = NSFont
public typealias PlatformView = NSView
public typealias PlatformTextView = NSTextView
#endif
