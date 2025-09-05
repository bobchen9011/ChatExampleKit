import SwiftUI
import FirebaseFirestore

internal struct MainTabView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var messageViewModel = MessageViewModel()
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // 首頁
            HomeView()
                .tabItem {
                    Image(systemName: selectedTab == 0 ? "house.fill" : "house")
                    Text("首頁")
                }
                .tag(0)
                .environmentObject(messageViewModel)
            
            // 訊息頁面
            MessageListView()
                .tabItem {
                    Image(systemName: selectedTab == 1 ? "message.fill" : "message")
                    Text("訊息")
                }
                .tag(1)
                .environmentObject(messageViewModel)
            
            // 個人資料
            ProfileView()
                .tabItem {
                    Image(systemName: selectedTab == 2 ? "person.fill" : "person")
                    Text("個人")
                }
                .tag(2)
        }
        .accentColor(Color.appPrimaryGreen)
        .environmentObject(authViewModel)
        .onAppear {
            // 當主頁面出現時，載入聊天室列表
            if let userId = authViewModel.currentUser?.id {
                messageViewModel.fetchChatRooms(for: userId)
            }
        }
    }
}

internal struct HomeView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var messageViewModel: MessageViewModel
    @State private var users: [User] = []
    @State private var isLoading = false
    
    var filteredUsers: [User] {
        users.filter { $0.id != authViewModel.currentUser?.id }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // 背景顏色
                Color.appBackgroundGreen
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // 歡迎訊息
                    VStack(alignment: .leading, spacing: 8) {
                        Text("歡迎回來！")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(Color.appPrimaryText)
                        
                        Text("選擇一個用戶開始聊天")
                            .font(.title3)
                            .foregroundColor(Color.appSecondaryText)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    .padding(.top)
                    
                    if isLoading {
                        Spacer()
                        ProgressView("載入用戶中...")
                            .progressViewStyle(CircularProgressViewStyle())
                        Spacer()
                    } else if filteredUsers.isEmpty {
                        Spacer()
                        VStack(spacing: 16) {
                            Image(systemName: "person.3")
                                .font(.system(size: 60))
                                .foregroundColor(.gray)
                            
                            Text("沒有其他用戶")
                                .font(.headline)
                                .foregroundColor(Color.appHintText)
                            
                            Text("等待其他用戶註冊")
                                .font(.subheadline)
                                .foregroundColor(Color.appSecondaryText)
                        }
                        Spacer()
                    } else {
                        // 用戶列表
                        List(filteredUsers) { user in
                            UserChatRow(user: user)
                                .environmentObject(authViewModel)
                                .environmentObject(messageViewModel)
                                .listRowSeparator(.hidden)
                                .listRowBackground(Color.clear)
                        }
                        .listStyle(PlainListStyle())
                        .scrollContentBackground(.hidden)
                        .padding(.top, 16)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                loadUsers()
            }
        }
    }
    
    private func loadUsers() {
        isLoading = true
        let db = Firestore.firestore()
        
        db.collection("users").limit(to: 50).getDocuments { snapshot, error in
            DispatchQueue.main.async {
                self.isLoading = false
                
                if let error = error {
                    print("載入用戶失敗: \(error)")
                    return
                }
                
                self.users = snapshot?.documents.compactMap { document in
                    try? document.data(as: User.self)
                } ?? []
                
                print("📋 載入了 \(self.users.count) 個用戶")
            }
        }
    }
}

internal struct ProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var showSignOutAlert = false
    @State private var showDeleteAlert = false
    @State private var showDeleteError = false
    @State private var deleteErrorMessage = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                // 背景顏色
                Color.appBackgroundGreen
                    .ignoresSafeArea()
                
                List {
                    // 用戶資料區塊
                    if let user = authViewModel.currentUser {
                        Section {
                            HStack(spacing: 16) {
                                AsyncImage(url: URL(string: user.profileImageUrl ?? "")) { image in
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                } placeholder: {
                                    Image(systemName: "person.crop.circle.fill")
                                        .font(.system(size: 50))
                                        .foregroundColor(.gray)
                                }
                                .frame(width: 60, height: 60)
                                .clipShape(Circle())
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(user.username)
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(Color.appPrimaryText)
                                    
                                    Text(user.email)
                                        .font(.subheadline)
                                        .foregroundColor(Color.appSecondaryText)
                                }
                                
                                Spacer()
                            }
                            .padding(.vertical, 8)
                        }
                        .listRowBackground(Color.appCardGreen)
                    }
                    
                    // 登出和刪除帳號
                    Section {
                        Button(action: {
                            showSignOutAlert = true
                        }) {
                            Label("登出", systemImage: "rectangle.portrait.and.arrow.right")
                                .foregroundColor(.red)
                        }
                        .listRowBackground(Color.appCardGreen)
                        
                        Button(action: {
                            showDeleteAlert = true
                        }) {
                            Label("刪除帳號", systemImage: "trash")
                                .foregroundColor(.red)
                        }
                        .listRowBackground(Color.appCardGreen)
                    }
                }
                .scrollContentBackground(.hidden)
                .listRowSeparator(.hidden)
            }
            .navigationTitle("個人資料")
            .navigationBarTitleDisplayMode(.large)
            .alert("登出確認", isPresented: $showSignOutAlert) {
                Button("取消", role: .cancel) { }
                Button("登出", role: .destructive) {
                    authViewModel.signOut()
                }
            } message: {
                Text("您確定要登出嗎？")
            }
            .alert("刪除帳號", isPresented: $showDeleteAlert) {
                Button("取消", role: .cancel) { }
                Button("刪除", role: .destructive) {
                    authViewModel.deleteAccount { success, error in
                        if !success {
                            deleteErrorMessage = error ?? "未知錯誤"
                            showDeleteError = true
                        }
                    }
                }
            } message: {
                Text("這個操作無法復原，您的所有資料將會被永久刪除。")
            }
            .alert("刪除失敗", isPresented: $showDeleteError) {
                Button("確定", role: .cancel) { }
            } message: {
                Text(deleteErrorMessage)
            }
        }
    }
}

// MARK: - UserChatRow Component
internal struct UserChatRow: View {
    let user: User
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var messageViewModel: MessageViewModel
    @State private var chatId: String = ""
    @State private var shouldNavigate = false
    @State private var isCreatingChat = false
    
    var body: some View {
        Button(action: {
            createChatRoomAndNavigate()
        }) {
            HStack(spacing: 16) {
                // 用戶頭像
                AsyncImage(url: URL(string: user.profileImageUrl ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Image(systemName: "person.crop.circle.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.gray)
                }
                .frame(width: 60, height: 60)
                .clipShape(Circle())
                
                // 用戶資訊
                VStack(alignment: .leading, spacing: 4) {
                    Text(user.username)
                        .font(.headline)
                        .foregroundColor(Color.appPrimaryText)
                    
                    Text(user.email)
                        .font(.subheadline)
                        .foregroundColor(Color.appSecondaryText)
                    
                    if isCreatingChat {
                        Text("建立聊天室中...")
                            .font(.caption)
                            .foregroundColor(.orange)
                    } else {
                        Text("點擊開始聊天")
                            .font(.caption)
                            .foregroundColor(Color.appPrimaryGreen)
                    }
                }
                
                Spacer()
                
                // 聊天圖標或載入指示器
                if isCreatingChat {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: "message.circle.fill")
                        .font(.title2)
                        .foregroundColor(Color.appPrimaryGreen)
                }
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(PlainButtonStyle())
        .background(
            NavigationLink(
                destination: ChatRoomView(
                    chatId: chatId,
                    otherUserId: user.id ?? "",
                    initialMessage: nil
                )
                .environmentObject(authViewModel),
                isActive: $shouldNavigate
            ) {
                EmptyView()
            }
                .hidden()
        )
    }
    
    private func createChatRoomAndNavigate() {
        guard let currentUserId = authViewModel.currentUser?.id,
              let otherUserId = user.id,
              !isCreatingChat else {
            print("❌ 無法建立聊天室 - 檢查條件失敗")
            return
        }
        
        isCreatingChat = true
        print("🚀 建立聊天室 - 當前用戶: \(authViewModel.currentUser?.username ?? ""), 目標用戶: \(user.username)")
        
        messageViewModel.createOrGetChatRoom(
            userId1: currentUserId,
            userId2: otherUserId
        ) { roomId, isNew in
            DispatchQueue.main.async {
                self.chatId = roomId
                self.isCreatingChat = false
                self.shouldNavigate = true
                print("✅ 聊天室建立完成，開始導航: \(roomId)")
            }
        }
    }
}

#Preview {
    MainTabView()
        .environmentObject(AuthViewModel())
}
