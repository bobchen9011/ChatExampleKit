import SwiftUI
import Photos

internal struct PhotoPreviewCropView: View {
    let asset: PHAsset
    @Binding var isPresented: Bool
    let onImageSelected: (UIImage) -> Void
    
    @State private var originalImage: UIImage?
    @State private var showFullScreen = false
    @State private var cornerRadius: CGFloat = 0
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // 照片預覽區域
                    photoPreviewArea
                    
                    // 控制區域
                    controlArea
                }
            }
            .navigationTitle("照片預覽")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("取消") {
                    isPresented = false
                },
                trailing: Button("完成") {
                    if let image = originalImage {
                        onImageSelected(image)
                    }
                    isPresented = false
                }
            )
        }
        .onAppear {
            loadOriginalImage()
        }
        .fullScreenCover(isPresented: $showFullScreen) {
            FullScreenPhotoView(
                asset: asset,
                isPresented: $showFullScreen
            )
        }
    }
    
    private var photoPreviewArea: some View {
        GeometryReader { geometry in
            if let image = originalImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                    .contentShape(Rectangle())
                    .onTapGesture {
                        // 點擊進入原圖大小查看
                        showFullScreen = true
                    }
            } else {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(maxHeight: UIScreen.main.bounds.height * 0.6)
        .background(Color.black)
    }
    
    private var controlArea: some View {
        VStack(spacing: 20) {
            // 圓角控制
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("圓角")
                        .foregroundColor(.white)
                        .font(.headline)
                    Spacer()
                    Text("\(Int(cornerRadius))")
                        .foregroundColor(.gray)
                }
                
                Slider(value: $cornerRadius, in: 0...50)
                    .accentColor(.blue)
            }
            
            
            Spacer()
            
            // 提示文字
            Text("點擊照片查看原圖")
                .foregroundColor(.gray)
                .font(.caption)
        }
        .padding(20)
        .background(Color.black)
    }
    
    private func loadOriginalImage() {
        let manager = PHImageManager.default()
        let requestOptions = PHImageRequestOptions()
        requestOptions.isSynchronous = false
        requestOptions.deliveryMode = .highQualityFormat
        
        manager.requestImage(
            for: asset,
            targetSize: CGSize(width: 800, height: 800),
            contentMode: .aspectFill,
            options: requestOptions
        ) { result, _ in
            DispatchQueue.main.async {
                self.originalImage = result
            }
        }
    }
}


internal struct FullScreenPhotoView: View {
    let asset: PHAsset
    @Binding var isPresented: Bool
    
    @State private var fullImage: UIImage?
    @State private var scale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastScale: CGFloat = 1.0
    @State private var lastOffset: CGSize = .zero
    @State private var showOriginalSize = false
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            if let image = fullImage {
                if showOriginalSize {
                    // 原始大小顯示 - 像第二張圖（原始比例，佈滿螢幕，固定不滑動，隱藏狀態欄）
                    ZStack {
                        Color.black.ignoresSafeArea(.all)
                        
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
                            .clipped()
                    }
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showOriginalSize = false
                        }
                    }
                } else {
                    // 全螢幕適配顯示 - 像第一張圖（固定位置，只能縮放）
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .scaleEffect(scale)
                        .gesture(
                            MagnificationGesture()
                                .onChanged { value in
                                    scale = lastScale * value
                                }
                                .onEnded { _ in
                                    lastScale = scale
                                    if scale < 1 {
                                        withAnimation(.spring()) {
                                            scale = 1
                                            lastScale = 1
                                        }
                                    }
                                }
                        )
                        .onTapGesture {
                            // 點擊進入原始大小模式
                            withAnimation(.easeInOut(duration: 0.3)) {
                                showOriginalSize = true
                                scale = 1.0
                                lastScale = 1.0
                            }
                        }
                    
                    // 全螢幕模式的 X 按鈕
                    VStack {
                        HStack {
                            Spacer()
                            Button(action: {
                                isPresented = false
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.title)
                                    .foregroundColor(.white)
                                    .background(Color.black.opacity(0.5))
                                    .clipShape(Circle())
                            }
                            .padding()
                        }
                        Spacer()
                    }
                }
            } else {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
            }
        }
        .statusBarHidden(showOriginalSize)
        .onAppear {
            loadFullImage()
        }
    }
    
    private func loadFullImage() {
        let manager = PHImageManager.default()
        let requestOptions = PHImageRequestOptions()
        requestOptions.isSynchronous = false
        requestOptions.deliveryMode = .highQualityFormat
        
        manager.requestImage(
            for: asset,
            targetSize: PHImageManagerMaximumSize,
            contentMode: .aspectFit,
            options: requestOptions
        ) { result, _ in
            DispatchQueue.main.async {
                self.fullImage = result
            }
        }
    }
}

#Preview {
    // 為預覽創建一個安全的版本，不使用真實的 PHAsset
    VStack {
        Text("Photo Preview Crop View")
            .font(.title)
            .foregroundColor(.white)
            .padding()
        
        Text("此組件需要真實的 PHAsset")
            .font(.caption)
            .foregroundColor(.gray)
            .padding()
        
        Text("在實際應用中運行以查看完整功能")
            .font(.caption2)
            .foregroundColor(.secondary)
            .multilineTextAlignment(.center)
            .padding()
        
        Spacer()
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.black)
}

