import SwiftUI
#if canImport(UIKit)
import UIKit
#endif
#if canImport(PhotosUI)
import PhotosUI
#endif

// MARK: - 照片庫選擇器 (使用自訂界面)
#if canImport(UIKit)
internal struct PhotoLibraryPicker: View {
    @Binding var isPresented: Bool
    let onImagesSelected: ([UIImage]) -> Void
    
    var body: some View {
        CustomPhotoPickerView(
            isPresented: $isPresented,
            onImagesSelected: onImagesSelected
        )
    }
}
#endif

#if canImport(UIKit)
#Preview {
    PhotoLibraryPicker(
        isPresented: .constant(true),
        onImagesSelected: { images in
            print("選擇了 \(images.count) 張照片")
        }
    )
}
#endif