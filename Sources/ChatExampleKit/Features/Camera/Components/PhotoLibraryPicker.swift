import SwiftUI
import UIKit
import PhotosUI

// MARK: - 照片庫選擇器 (使用自訂界面)
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

#Preview {
    PhotoLibraryPicker(
        isPresented: .constant(true),
        onImagesSelected: { images in
            print("選擇了 \(images.count) 張照片")
        }
    )
}