import SwiftUI

internal struct UserSearchView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var messageViewModel: MessageViewModel
    @StateObject private var viewModel = UserSearchViewModel()
    
    var body: some View {
        NavigationView {
            ZStack {
                // 背景顏色
Color.appBackgroundGreen
                    .ignoresSafeArea()
                
                VStack {
                // 搜尋欄
                SearchBar(text: $viewModel.searchText)
                    .padding(.horizontal)
                
                if viewModel.isLoading {
                    Spacer()
                    ProgressView("搜尋用戶中...")
                    Spacer()
                } else if viewModel.filteredUsers(currentUserId: authViewModel.currentUser?.id).isEmpty && !viewModel.searchText.isEmpty {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "person.crop.circle.badge.questionmark")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        
                        Text("找不到用戶")
                            .font(.headline)
                            .foregroundColor(Color.appHintText)
                        
                        Text("試試其他的搜尋關鍵字")
                            .font(.subheadline)
                            .foregroundColor(Color.appSecondaryText)
                    }
                    Spacer()
                } else {
                    List(viewModel.filteredUsers(currentUserId: authViewModel.currentUser?.id)) { user in
                        UserRowView(user: user) {
                            startChatWith(user: user)
                        }
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.appCardGreen)
                    }
                    .listStyle(PlainListStyle())
                    .scrollContentBackgroundCompat(.hidden)
                }
                }
            }
            .navigationTitle("尋找用戶")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                trailing: Button("取消") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
            .onAppear {
                viewModel.loadUsers()
            }
        }
        .background(
            NavigationLink(
                destination: ChatRoomView(
                    chatId: viewModel.selectedChatId,
                    otherUserId: "",
                    initialMessage: nil
                )
                .environmentObject(authViewModel),
                isActive: $viewModel.navigateToChatRoom
            ) {
                EmptyView()
            }
            .hidden()
        )
    }
    
    private func startChatWith(user: User) {
        guard let currentUserId = authViewModel.currentUser?.id else { return }
        
        viewModel.startChatWith(
            user: user,
            currentUserId: currentUserId,
            messageViewModel: messageViewModel
        ) {
            presentationMode.wrappedValue.dismiss()
        }
    }
}

#Preview {
    UserSearchView()
        .environmentObject(AuthViewModel())
        .environmentObject(MessageViewModel())
}