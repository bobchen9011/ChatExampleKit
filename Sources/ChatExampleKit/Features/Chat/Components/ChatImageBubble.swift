import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

// MARK: - 聊天圖片氣泡組件
internal struct ChatImageBubble: View {
    let message: Message
    let isIncoming: Bool
    let maxWidth: CGFloat
    let onImageLoaded: (() -> Void)?
    
    // Cross-platform screen dimensions
    private var screenWidth: CGFloat {
#if canImport(UIKit)
        return UIScreen.main.bounds.width
#else
        return 400
#endif
    }
    
    private var screenHeight: CGFloat {
#if canImport(UIKit)
        return UIScreen.main.bounds.height
#else
        return 600
#endif
    }
    
    @State private var showFullScreenImage = false
    @State private var imageLoadFailed = false
    
    init(message: Message, isIncoming: Bool, maxWidth: CGFloat, onImageLoaded: (() -> Void)? = nil) {
        self.message = message
        self.isIncoming = isIncoming
        self.maxWidth = maxWidth
        self.onImageLoaded = onImageLoaded
    }
    
    var body: some View {
        VStack(alignment: isIncoming ? .leading : .trailing, spacing: 4) {
            // 圖片內容 - 不包裝在氣泡中
            imageContentView
                .onTapGesture {
                    showFullScreenImage = true
                }
            
            // 圖片說明文字（如果有的話）- 單獨顯示在圖片下方
            if message.hasTextContent {
                Text(message.content)
                    .font(.body)
                    .foregroundColor(isIncoming ? Color.appPrimaryText : .white)
                    .multilineTextAlignment(isIncoming ? .leading : .trailing)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(isIncoming ? Color.appCardGreen : Color.appPrimaryGreen)
                    )
                    .frame(maxWidth: maxWidth * 0.7, alignment: isIncoming ? .leading : .trailing)
            }
        }
        .frame(maxWidth: maxWidth, alignment: isIncoming ? .leading : .trailing)
        .fullScreenCover(isPresented: $showFullScreenImage) {
            FullScreenImageView(message: message, isPresented: $showFullScreenImage)
        }
    }
    
    // MARK: - 圖片內容視圖
    private var imageContentView: some View {
        Group {
            if let imageUrl = message.imageUrl, !imageUrl.isEmpty, !imageLoadFailed {
                // 使用 AsyncImage 載入網路圖片 (iOS 15+)
                AsyncImage(url: URL(string: imageUrl)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 150, height: 150)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(
                            // 上傳狀態覆蓋層
                            uploadStatusOverlay
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                        )
                        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                        .onAppear {
                            // 圖片加載完成，通知父視圖滾動
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                onImageLoaded?()
                            }
                        }
                } placeholder: {
                    imagePlaceholder
                }
            } else if let localPath = message.imageLocalPath,
                      let image = UIImage(contentsOfFile: localPath) {
                // 使用本地圖片
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 150, height: 150)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(
                        // 上傳狀態覆蓋層
                        uploadStatusOverlay
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    )
                    .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                    .onAppear {
                        // 本地圖片顯示完成，通知父視圖滾動
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            onImageLoaded?()
                        }
                    }
            } else {
                // 圖片載入失敗或不存在
                imageErrorView
            }
        }
    }
    
    // MARK: - 圖片佔位符
    private var imagePlaceholder: some View {
        VStack(spacing: 8) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle())
                .scaleEffect(1.2)
            
            Text("載入中...")
                .font(.caption)
                .foregroundColor(Color.appHintText)
        }
        .frame(width: 150, height: 150)
        .background(Color.appLightCardGreen)
        .cornerRadius(16)
    }
    
    // MARK: - 圖片錯誤視圖
    private var imageErrorView: some View {
        VStack(spacing: 8) {
            Image(systemName: "photo")
                .font(.system(size: 30))
                .foregroundColor(Color.appHintText)
            
            Text("圖片無法載入")
                .font(.caption)
                .foregroundColor(Color.appHintText)
        }
        .frame(width: 150, height: 150)
        .background(Color.appLightCardGreen)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
    
    // MARK: - 上傳狀態覆蓋層
    @ViewBuilder
    private var uploadStatusOverlay: some View {
        if message.uploadStatus == .uploading {
            ZStack {
                Color.black.opacity(0.5)
                    .cornerRadius(12)
                
                VStack(spacing: 8) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.2)
                    
                    Text("上傳中...")
                        .font(.caption)
                        .foregroundColor(.white)
                        .fontWeight(.medium)
                }
            }
        } else if message.uploadStatus == .failed {
            ZStack {
                Color.red.opacity(0.7)
                    .cornerRadius(12)
                
                VStack(spacing: 4) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                    
                    Text("上傳失敗")
                        .font(.caption)
                        .foregroundColor(.white)
                        .fontWeight(.medium)
                }
            }
        }
    }
}

// MARK: - 全螢幕圖片查看器
internal struct FullScreenImageView: View {
    let message: Message
    @Binding var isPresented: Bool
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    @State private var showOriginalSize = false
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            if let imageUrl = message.imageUrl, !imageUrl.isEmpty {
                AsyncImage(url: URL(string: imageUrl)) { image in
                    imageDisplayView(image: image)
                } placeholder: {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                }
            } else if let localPath = message.imageLocalPath,
                      let image = UIImage(contentsOfFile: localPath) {
                imageDisplayView(image: Image(uiImage: image))
            }
            
            // X 按鈕 - 僅在非原始大小模式顯示
            if !showOriginalSize {
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
        }
        .statusBarHidden(showOriginalSize)
    }
    
    @ViewBuilder
    private func imageDisplayView(image: Image) -> some View {
        if showOriginalSize {
            // 原始大小顯示 - 像第二張圖（原始比例，佈滿螢幕，固定不滑動，隱藏狀態欄）
            ZStack {
                Color.black.ignoresSafeArea(.all)
                
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: screenWidth, height: screenHeight)
                    .clipped()
            }
            .onTapGesture {
                withAnimation(.easeInOut(duration: 0.3)) {
                    showOriginalSize = false
                }
            }
        } else {
            // 全螢幕適配顯示 - 像第一張圖（固定位置，只能縮放）
            image
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
        }
    }
}


#Preview {
    VStack(spacing: 16) {
        // 發送的圖片訊息
        ChatImageBubble(
            message: Message(
                id: "1",
                chatId: "chat1",
                senderId: "user1",
                content: "這是一張美麗的風景照",
                timestamp: Date(),
                isRead: true,
                messageType: .imageWithText,
                imageUrl: "https://picsum.photos/300/200",
                imageSize: ImageSize(width: 300, height: 200),
                uploadStatus: .completed
            ),
            isIncoming: false,
            maxWidth: 300,
            onImageLoaded: {}
        )
        
        // 接收的純圖片訊息
        ChatImageBubble(
            message: Message(
                id: "2",
                chatId: "chat1",
                senderId: "user2",
                content: "",
                timestamp: Date(),
                isRead: true,
                messageType: .image,
                imageUrl: "https://picsum.photos/200/300",
                imageSize: ImageSize(width: 200, height: 300),
                uploadStatus: .completed
            ),
            isIncoming: true,
            maxWidth: 300,
            onImageLoaded: {}
        )
    }
    .padding()
    .background(Color.appLightCardGreen)
}