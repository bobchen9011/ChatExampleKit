import SwiftUI

// MARK: - View Extensions for iOS Compatibility
internal extension View {
    /// Apply a modifier conditionally based on iOS version
    @ViewBuilder
    func apply<T: View>(@ViewBuilder _ modifier: (Self) -> T) -> some View {
        modifier(self)
    }
    
    /// iOS 16+ scrollContentBackground with fallback
    @ViewBuilder
    func scrollContentBackgroundCompat(_ visibility: Visibility) -> some View {
        if #available(iOS 16.0, *) {
            self.scrollContentBackground(visibility)
        } else {
            self
        }
    }
    
    /// iOS 16+ lineLimit with ClosedRange fallback
    @ViewBuilder
    func lineLimitCompat(_ range: ClosedRange<Int>) -> some View {
        if #available(iOS 16.0, *) {
            self.lineLimit(range)
        } else {
            // iOS 15 fallback: use maximum value from range
            self.lineLimit(range.upperBound)
        }
    }
    
    /// iOS 16+ toolbar with placement fallback
    @ViewBuilder
    func toolbarCompat<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        if #available(iOS 16.0, *) {
            self.toolbar(content: content)
        } else {
            // iOS 15 fallback: use traditional toolbar
            self.toolbar {
                content()
            }
        }
    }
    
    /// iOS 16+ toolbar visibility with fallback
    @ViewBuilder
    func toolbarVisibilityCompat(_ visibility: Visibility, for placement: ToolbarPlacement) -> some View {
        if #available(iOS 16.0, *) {
            self.toolbar(visibility, for: placement)
        } else {
            // iOS 15 fallback: no effect since toolbar visibility control not available
            self
        }
    }
}