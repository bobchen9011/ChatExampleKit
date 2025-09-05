import SwiftUI

// MARK: - 自訂相機界面
internal struct CustomCameraView: View {
    @Binding var isPresented: Bool
    @Binding var capturedImage: UIImage?
    
    @StateObject private var viewModel = CameraViewModel()
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            if viewModel.showImagePreview, let image = viewModel.capturedImage {
                // 跳轉到圖片預覽
                PhotoPreviewView(
                    image: image,
                    isPresented: $viewModel.showImagePreview,
                    onSend: { finalImage in
                        viewModel.sendPhoto(finalImage) { processedImage in
                            capturedImage = processedImage
                            isPresented = false
                        }
                    },
                    onCancel: {
                        viewModel.cancelPhotoPreview()
                    }
                )
            } else {
                // 相機界面
                cameraView
            }
        }
        .onAppear {
            viewModel.startCameraSession()
        }
        .onDisappear {
            viewModel.stopCameraSession()
        }
        .alert("相機錯誤", isPresented: $viewModel.showError) {
            Button("確定") {
                viewModel.showError = false
                viewModel.errorMessage = ""
            }
        } message: {
            Text(viewModel.errorMessage)
        }
        .fullScreenCover(isPresented: $viewModel.showPhotoLibrary) {
            PhotoLibraryPicker(
                isPresented: $viewModel.showPhotoLibrary,
                onImagesSelected: { images in
                    viewModel.selectPhotosFromLibrary(images)
                }
            )
        }
    }
    
    // MARK: - 相機界面
    private var cameraView: some View {
        VStack(spacing: 0) {
            // 頂部留空給動態島
            Spacer()
                .frame(height: 50)
            
            // 相機預覽區域（包含所有控制元件）
            ZStack {
                // 相機預覽
                CameraPreviewComponent(viewModel: viewModel)
                    .clipped()
                    .cornerRadius(20)
                
                // 浮動控制按鈕
                CameraControlsView(viewModel: viewModel) {
                    isPresented = false
                }
            }
            
            // 底部留空給安全區域
            Spacer()
                .frame(height: 50)
        }
        .ignoresSafeArea(edges: .top)
    }
}

#Preview {
    // 預覽中顯示佔位符而不是真實的相機界面
    ZStack {
        Color.black.ignoresSafeArea()
        
        VStack(spacing: 20) {
            Spacer()
                .frame(height: 50)
            
            VStack(spacing: 16) {
                Image(systemName: "camera")
                    .font(.system(size: 80))
                    .foregroundColor(.white)
                
                Text("自訂相機界面")
                    .font(.title)
                    .foregroundColor(.white)
                
                Text("此組件需要在真實設備上運行")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
                .frame(height: 50)
        }
    }
}