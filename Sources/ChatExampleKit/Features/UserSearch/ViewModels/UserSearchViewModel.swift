import Foundation
import FirebaseFirestore

internal class UserSearchViewModel: ObservableObject {
    @Published var searchText = ""
    @Published var users: [User] = []
    @Published var isLoading = false
    @Published var navigateToChatRoom = false
    @Published var selectedChatId = ""
    
    func filteredUsers(currentUserId: String?) -> [User] {
        if searchText.isEmpty {
            return users.filter { $0.id != currentUserId }
        } else {
            return users.filter { user in
                user.id != currentUserId &&
                (user.username.localizedCaseInsensitiveContains(searchText) ||
                 user.email.localizedCaseInsensitiveContains(searchText))
            }
        }
    }
    
    func loadUsers() {
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
            }
        }
    }
    
    func startChatWith(
        user: User,
        currentUserId: String,
        messageViewModel: MessageViewModel,
        completion: @escaping () -> Void
    ) {
        guard let otherUserId = user.id else { return }
        
        messageViewModel.createOrGetChatRoom(
            userId1: currentUserId,
            userId2: otherUserId
        ) { chatId, isNew in
            DispatchQueue.main.async {
                self.selectedChatId = chatId
                self.navigateToChatRoom = true
                completion()
            }
        }
    }
}