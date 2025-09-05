import SwiftUI

// MARK: - 相機控制按鈕組件
internal struct CameraControlsView: View {
    let viewModel: CameraViewModel
    let onClose: () -> Void
    
    var body: some View {
        VStack {
            // 頂部按鈕組
            topButtons
            
            Spacer()
            
            // 底部按鈕組
            bottomButtons
        }
    }
    
    // MARK: - 頂部按鈕組
    private var topButtons: some View {
        HStack {
            // 關閉按鈕
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(Color.gray.opacity(0.3))
                    .clipShape(Circle())
            }
            
            Spacer()
            
            // 切換鏡頭按鈕
            Button(action: {
                viewModel.switchCamera()
            }) {
                Image(systemName: "arrow.triangle.2.circlepath.camera")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(Color.gray.opacity(0.3))
                    .clipShape(Circle())
            }
            
            Spacer()
            
            // 閃光燈按鈕
            Button(action: {
                viewModel.toggleFlash()
            }) {
                Image(systemName: viewModel.isFlashOn ? "bolt.fill" : "bolt.slash.fill")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(Color.gray.opacity(0.3))
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 10) // 動態島空間
    }
    
    // MARK: - 底部按鈕組
    private var bottomButtons: some View {
        HStack {
            // 相簿按鈕
            Button(action: {
                viewModel.showPhotoLibrary = true
            }) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 44, height: 44)
                    .overlay(
                        Image(systemName: "photo")
                            .foregroundColor(.white)
                    )
            }
            
            Spacer()
            
            // 拍照按鈕
            Button(action: {
                viewModel.capturePhoto()
            }) {
                ZStack {
                    Circle()
                        .stroke(Color.white, lineWidth: 6)
                        .frame(width: 72, height: 72)
                    
                    Circle()
                        .fill(Color.white)
                        .frame(width: 60, height: 60)
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, 30)
        .padding(.bottom, 34)
    }
}

#Preview {
    CameraControlsView(
        viewModel: CameraViewModel(),
        onClose: {}
    )
}
