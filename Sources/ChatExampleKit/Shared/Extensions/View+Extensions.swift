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
    func toolbarVisibilityCompat<T>(_ visibility: Visibility, for placement: T) -> some View {
        if #available(iOS 16.0, *) {
            // Use runtime check to avoid compile-time ToolbarPlacement reference
            self.modifier(ToolbarVisibilityModifier(visibility: visibility, placement: placement))
        } else {
            // iOS 15 fallback: no effect since toolbar visibility control not available
            self
        }
    }
    
    /// iOS 16+ TextField axis with fallback
    @ViewBuilder
    static func textFieldCompat(_ placeholder: String, text: Binding<String>, axis: Axis = .horizontal) -> some View {
        if #available(iOS 16.0, *) {
            TextField(placeholder, text: text, axis: axis)
        } else {
            // iOS 15 fallback: regular TextField
            TextField(placeholder, text: text)
        }
    }
}

// MARK: - ToolbarPlacement Helpers
internal struct ToolbarPlacementTabBar {
    // Empty struct that can be used as a placeholder
}

internal extension View {
    /// Helper function to get tabBar placement for toolbar
    func toolbarTabBarCompat(_ visibility: Visibility) -> some View {
        if #available(iOS 16.0, *) {
            return AnyView(self.toolbar(visibility, for: .tabBar))
        } else {
            return AnyView(self)
        }
    }
}

// MARK: - iOS 16+ Toolbar Visibility Modifier
@available(iOS 16.0, *)
internal struct ToolbarVisibilityModifier<T>: ViewModifier {
    let visibility: Visibility
    let placement: T
    
    func body(content: Content) -> some View {
        if let toolbarPlacement = placement as? ToolbarPlacement {
            content.toolbar(visibility, for: toolbarPlacement)
        } else {
            content
        }
    }
}