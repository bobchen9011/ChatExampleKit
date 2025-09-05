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
}