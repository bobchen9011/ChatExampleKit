import SwiftUI

// MARK: - 照片預覽界面
internal struct PhotoPreviewView: View {
    let image: UIImage
    @Binding var isPresented: Bool
    let onSend: (UIImage) -> Void
    let onCancel: () -> Void
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // 頂部留空給動態島
                Spacer()
                    .frame(height: 50)
                
                // 圖片預覽區域（包含浮動控制元件）
                ZStack {
                    imagePreviewArea
                    
                    // 頂部控制欄浮動在圖片上方
                    VStack {
                        topControlBar
                        Spacer()
                    }
                    
                }
                
                // 底部控制欄
                bottomControlBar
            }
            .ignoresSafeArea(edges: .top)
        }
    }
    
    // MARK: - 頂部控制欄（完整編輯工具欄）
    private var topControlBar: some View {
        HStack {
            // 左側 X 按鈕
            Button(action: {
                onCancel()
                isPresented = false
            }) {
                Image(systemName: "xmark")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
            }
            
            Spacer()
            
            // 右側編輯工具按鈕組
            HStack(spacing: 20) {
                // 更多按鈕
                Button(action: {}) {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 10) // 恢復原本的 padding
        .background(Color.clear)
        .frame(height: 100) // 恢復原本高度
    }
    
    // MARK: - 圖片預覽
    private var imagePreviewArea: some View {
        GeometryReader { geometry in
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: geometry.size.width, height: geometry.size.height)
                .clipped()
                .cornerRadius(20)
        }
    }
    
    // MARK: - 底部控制欄（HD + 發送按鈕樣式）
    private var bottomControlBar: some View {
        HStack {
            // 左側 HD 畫質標籤
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("HD")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.white.opacity(0.2))
                        )
                    
                    Spacer()
                }
                
                Text("畫質")
                    .font(.system(size: 14))
                    .foregroundColor(.white)
            }
            
            Spacer()
            
            // 右側發送按鈕
            Button(action: {
                onSend(image)
                isPresented = false
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.gray)
                    
                    Text("發送")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.black)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color.white)
                .clipShape(Capsule())
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 10) // 安全區域
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.clear, Color.black.opacity(0.7)]),
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .frame(height: 90)
    }
}
// MARK: - 預覽
#Preview {
    PhotoPreviewView(
        image: UIImage(systemName: "photo") ?? UIImage(),
        isPresented: .constant(true),
        onSend: { _ in },
        onCancel: {}
    )
}
