import SwiftUI
import Combine

// 鍵盤高度監聽
internal class KeyboardResponder: ObservableObject {
    @Published var keyboardHeight: CGFloat = 0
    @Published var isKeyboardVisible: Bool = false
    private var cancellableSet: Set<AnyCancellable> = []
    
    init() {
        NotificationCenter.default.publisher(for: UIResponder.keyboardWillChangeFrameNotification)
            .merge(with: NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification))
            .sink { notification in
                if let frame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                    let screenHeight = UIScreen.main.bounds.height
                    let safeAreaBottom = UIApplication.shared.connectedScenes
                        .compactMap { $0 as? UIWindowScene }
                        .flatMap { $0.windows }
                        .first { $0.isKeyWindow }?.safeAreaInsets.bottom ?? 0
                    self.keyboardHeight = max(0, screenHeight - frame.origin.y - safeAreaBottom)
                    self.isKeyboardVisible = self.keyboardHeight > 0
                    print("鍵盤高度: \(self.keyboardHeight), 安全區域底部: \(safeAreaBottom)")
                } else {
                    self.keyboardHeight = 0
                    self.isKeyboardVisible = false
                    print("鍵盤隱藏，高度設為 0")
                }
            }
            .store(in: &cancellableSet)
    }
}

internal struct ChatRoomView: View {
    let chatId: String
    let otherUserId: String
    let initialMessage: String?
    
    @StateObject private var messageVM = MessageViewModel()
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var inputText: String = ""
    @State private var hasSentInitialMessage = false
    @State private var isInitialLoad = true
    @FocusState private var isTextFieldFocused: Bool
    @StateObject private var keyboard = KeyboardResponder()
    @State private var showTabBar = false
    
    // 圖片訊息相關狀態
    @State private var selectedImage: UIImage?
    @State private var showPhotoButtons = false
    @State private var showCameraInterface = false
    @State private var showPhotoLibrary = false
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 0) {
            // 訊息列表
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(messageVM.messages.indices, id: \.self) { index in
                            let msg = messageVM.messages[index]
                            let isLastInGroup = messageVM.isLastMessageInGroup(at: index)
                            let isCurrentUser = msg.senderId == authViewModel.currentUser?.id
                            let shouldShowRead = messageVM.shouldShowReadStatus(at: index, currentUserId: authViewModel.currentUser?.id ?? "")
                            
                            if messageVM.shouldShowDateSeparator(at: index) {
                                DateSeparatorView(
                                    date: msg.timestamp,
                                    messageViewModel: messageVM
                                )
                            }
                            
                            MessageBubbleView(
                                message: msg,
                                hasTail: isLastInGroup,
                                isCurrentUser: isCurrentUser,
                                shouldShowReadStatus: shouldShowRead
                            )
                            .id(msg.id)
                        }
                        
                        if !messageVM.messages.isEmpty {
                            Spacer()
                                .frame(height: 8)
                                .id("bottomSpacer")
                        }
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 8)
                    .flipsForRightToLeftLayoutDirection(false)
                }
                .background(Color.appBackgroundGreen) // 護眼綠 #CCE8CF
                .ignoresSafeArea(.keyboard)
                .onTapGesture {
                    isTextFieldFocused = false
                }
                .onAppear {
                    if let initialMessage = initialMessage, !hasSentInitialMessage {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            sendInitialMessage(initialMessage)
                        }
                    }
                }
                .onChange(of: messageVM.messages.count) { _ in
                    guard !messageVM.messages.isEmpty else { return }
                    if isInitialLoad {
                        // 初始載入時立即滾動
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            proxy.scrollTo("bottomSpacer", anchor: .bottom)
                            isInitialLoad = false
                        }
                        if let userId = authViewModel.currentUser?.id {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                messageVM.markMessagesAsRead(chatId: chatId, currentUserId: userId)
                            }
                        }
                    } else {
                        // 新訊息時自動滾動到底部
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            withAnimation(.easeOut(duration: 0.3)) {
                                proxy.scrollTo("bottomSpacer", anchor: .bottom)
                            }
                        }
                        // 收到新訊息時即時標記為已讀
                        if let userId = authViewModel.currentUser?.id {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                messageVM.markMessagesAsRead(chatId: chatId, currentUserId: userId)
                            }
                        }
                    }
                }
                .onChange(of: keyboard.keyboardHeight) { _ in
                    // 鍵盤變化時總是滾動到底部（這是必要的UX）
                    DispatchQueue.main.async {
                        if !messageVM.messages.isEmpty {
                            proxy.scrollTo("bottomSpacer", anchor: .bottom)
                        }
                    }
                }
            }
            
            // 輸入框區域
            MessageInputView(
                inputText: $inputText,
                showPhotoButtons: $showPhotoButtons,
                showCameraInterface: $showCameraInterface,
                showPhotoLibrary: $showPhotoLibrary,
                selectedImage: $selectedImage,
                isTextFieldFocused: $isTextFieldFocused,
                onSend: send,
                onImageSelected: { image in
                    sendImageMessage(image: image, caption: "")
                }
            )
            .padding(.bottom, keyboard.keyboardHeight)
            .animation(.easeOut(duration: 0.25), value: keyboard.keyboardHeight)
        }
        .navigationTitle("聊天室")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color.appBackgroundGreen)
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .toolbar(showTabBar ? .visible : .hidden, for: .tabBar)
        .onAppear {
            DispatchQueue.main.async {
                showTabBar = false
            }
            messageVM.fetchMessages(for: chatId)
            NotificationCenter.default.addObserver(
                forName: UIApplication.willEnterForegroundNotification,
                object: nil,
                queue: .main
            ) { _ in
                if let userId = authViewModel.currentUser?.id {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        messageVM.markMessagesAsRead(chatId: chatId, currentUserId: userId)
                    }
                }
            }
        }
        .onDisappear {
            DispatchQueue.main.async {
                showTabBar = true
            }
            if let userId = authViewModel.currentUser?.id {
                messageVM.markMessagesAsRead(chatId: chatId, currentUserId: userId)
            }
        }
    }
    
    
    
    private func send() {
        guard let userId = authViewModel.currentUser?.id else { return }
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        
        messageVM.sendMessage(chatId: chatId, text: text, senderId: userId)
        inputText = ""
        isTextFieldFocused = true
    }
    
    private func sendInitialMessage(_ message: String) {
        guard let userId = authViewModel.currentUser?.id else { return }
        let text = message.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        messageVM.sendMessage(chatId: chatId, text: text, senderId: userId)
        hasSentInitialMessage = true
        isTextFieldFocused = true
    }
    
    // 發送圖片訊息
    private func sendImageMessage(image: UIImage, caption: String) {
        guard let userId = authViewModel.currentUser?.id else { return }
        
        messageVM.sendImageMessage(
            chatId: chatId,
            image: image,
            caption: caption,
            senderId: userId
        )
        
        // 重置狀態
        selectedImage = nil
        // 重置狀態
        
        // 發送圖片表示用戶正在積極使用聊天室，標記所有訊息為已讀
        messageVM.markMessagesAsRead(chatId: chatId, currentUserId: userId)
    }
}

#Preview {
    NavigationView {
        ChatRoomView(chatId: "preview", otherUserId: "other", initialMessage: nil)
            .environmentObject(AuthViewModel())
            .environmentObject(MessageViewModel())
    }
}
