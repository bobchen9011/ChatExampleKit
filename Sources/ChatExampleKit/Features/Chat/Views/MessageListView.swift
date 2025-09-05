import SwiftUI

internal struct MessageListView: View {
    @EnvironmentObject var messageViewModel: MessageViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    
    @State private var selectedChatId: String? = nil
    @State private var refreshTimer: Timer?
    
    var body: some View {
        NavigationView {
            ZStack {
                backgroundColor
                chatList
            }
            .navigationTitle("訊息")
            .navigationBarTitleDisplayMode(.large)
        }
        .onAppear(perform: setupView)
        .onDisappear(perform: cleanupTimer)
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            refreshChatRooms()
        }
    }
    
    // MARK: - 背景
    private var backgroundColor: some View {
        Color.appBackgroundGreen
            .ignoresSafeArea()
    }
    
    // MARK: - 聊天列表
    @ViewBuilder
    private var chatList: some View {
        if messageViewModel.chatRooms.isEmpty {
            VStack(spacing: 20) {
                Spacer()
                
                Image(systemName: "message")
                    .font(.system(size: 60))
                    .foregroundColor(.gray)
                
                Text("還沒有對話")
                    .font(.title2)
                    .fontWeight(.medium)
                    .foregroundColor(Color.appHintText)
                
                Text("到首頁開始新的對話吧！")
                    .font(.subheadline)
                    .foregroundColor(Color.appSecondaryText)
                
                Spacer()
            }
        } else {
            List {
                ForEach(messageViewModel.chatRooms) { chat in
                    chatRow(for: chat)
                        .listRowBackground(Color.appCardGreen)
                }
            }
            .listStyle(InsetGroupedListStyle())
            .scrollContentBackgroundCompat(.hidden)
        }
    }
    
    // MARK: - 單個聊天列
    private func chatRow(for chat: ChatRoom) -> some View {
        ChatListRowView(messageViewModel: messageViewModel, chatRoom: chat)
            .environmentObject(authViewModel)
            .contentShape(Rectangle()) // 確保整行都可點擊
            .onTapGesture {
                selectedChatId = chat.id
            }
            .background(
                NavigationLink(
                    destination: ChatRoomView(
                        chatId: chat.id ?? "",
                        otherUserId: chat.participants.first(where: { $0 != authViewModel.currentUser?.id }) ?? "",
                        initialMessage: nil
                    )
                    .environmentObject(authViewModel),
                    tag: chat.id ?? "",
                    selection: $selectedChatId
                ) { EmptyView() }
                .hidden()
            )
    }
    
    // MARK: - Lifecycle
    private func setupView() {
        if let userId = authViewModel.currentUser?.id {
            messageViewModel.fetchChatRooms(for: userId)
        }
        
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
            refreshChatRooms()
        }
    }
    
    private func cleanupTimer() {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }
    
    private func refreshChatRooms() {
        if let userId = authViewModel.currentUser?.id {
            messageViewModel.fetchChatRooms(for: userId)
        }
    }
}

internal struct ChatListRowView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @ObservedObject var messageViewModel: MessageViewModel
    let chatRoom: ChatRoom
    
    @State private var opponentUser: User? = nil
    
    // 找到對方的 userId
    private var opponentUserId: String? {
        chatRoom.participants.first(where: { $0 != authViewModel.currentUser?.id })
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            // 對方頭像
            ZStack(alignment: .topTrailing) {
                AsyncImage(url: URL(string: opponentUser?.profileImageUrl ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Image(systemName: "person.crop.circle.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .foregroundColor(.gray.opacity(0.6))
                }
                .frame(width: 52, height: 52)
                .clipShape(Circle())
                
                // 未讀訊息指示器 - 頭像右上角
                if chatRoom.unreadCount > 0 {
                    ZStack {
                        Circle()
                            .fill(Color.red)
                            .frame(width: chatRoom.unreadCount > 9 ? 26 : 22, 
                                  height: chatRoom.unreadCount > 9 ? 26 : 22)
                            .shadow(color: .black.opacity(0.3), radius: 2, x: 1, y: 1)
                        
                        Text("\(min(chatRoom.unreadCount, 99))")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .minimumScaleFactor(0.6)
                    }
                    .offset(x: 8, y: -8)
                    .zIndex(1)
                }
                
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline) {
                    // 對方暱稱
                    let hasUnreadMessages = chatRoom.unreadCount > 0
                    
                    Text(opponentUser?.username ?? "未知用戶")
                        .font(.headline)
                        .fontWeight(hasUnreadMessages ? .bold : .semibold)
                        .foregroundColor(Color.appPrimaryText)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    // 最後訊息時間
                    if let timestamp = chatRoom.lastTimestamp {
                         Text(formattedTimestamp(timestamp))
                            .font(.caption)
                            .fontWeight(hasUnreadMessages ? .semibold : .regular)
                            .foregroundColor(hasUnreadMessages ? Color.appPrimaryText : Color.appSecondaryText)
                    }
                }
                
                // 最後一則訊息
                HStack(spacing: 4) {
                    // 檢查最後訊息是否是自己發送的
                    let isLastMessageFromMe = chatRoom.lastMessageSenderId == authViewModel.currentUser?.id
                    let messagePrefix = isLastMessageFromMe ? "你: " : ""
                    
                    // 檢查是否有未讀訊息（不管是誰發的，只要有未讀就顯示粗體）
                    let hasUnreadMessages = chatRoom.unreadCount > 0
                    
                    Text(messagePrefix + (chatRoom.lastMessage ?? "開始對話"))
                        .font(.subheadline)
                        .fontWeight(hasUnreadMessages ? .bold : .regular)
                        .foregroundColor(hasUnreadMessages ? Color.appPrimaryText : Color.appSecondaryText)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    // 顯示已讀取狀態（只有當最後訊息是自己發送時才顯示）
                    if let _ = chatRoom.lastMessage,
                       let currentUserId = authViewModel.currentUser?.id,
                       let lastMessageSenderId = chatRoom.lastMessageSenderId,
                       lastMessageSenderId == currentUserId {
                        Image(systemName: chatRoom.lastMessageIsRead ? "checkmark.circle.fill" : "checkmark.circle")
                            .foregroundColor(chatRoom.lastMessageIsRead ? .green : .gray)
                            .font(.caption)
                    }
                }
            }
        }
        .padding(.vertical, 8)
        .onAppear {
            // 載入對方用戶資料
            if let userId = opponentUserId {
                messageViewModel.fetchUserData(for: userId) { user in
                    self.opponentUser = user
                }
            }
        }
    }
    
    // 時間格式化
    private func formattedTimestamp(_ date: Date) -> String {
        let formatter = DateFormatter()
        if Calendar.current.isDateInToday(date) {
            formatter.dateFormat = "HH:mm"
        } else if Calendar.current.isDateInYesterday(date) {
             return "昨天"
        } else if Calendar.current.isDate(date, equalTo: Date(), toGranularity: .weekOfYear) {
             formatter.dateFormat = "EEE"
        } else {
             formatter.dateFormat = "MM/dd"
        }
        return formatter.string(from: date)
    }
}

#Preview {
    MessageListView()
        .environmentObject(MessageViewModel())
        .environmentObject(AuthViewModel())
}

