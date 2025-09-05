import Foundation
import FirebaseFirestore

internal class FirestoreListenerManager {
    static let shared = FirestoreListenerManager()
    
    private var listeners: [String: ListenerRegistration] = [:]
    
    private init() {}
    
    // MARK: - Chat Room Listener
    func createChatRoomListener(userId: String, completion: @escaping (QuerySnapshot?, Error?) -> Void) -> String {
        let listenerKey = "chatrooms_\(userId)"
        
        // Remove existing listener if any
        removeListener(for: listenerKey)
        
        print("🔄 設置聊天室監聽器 for user: \(userId)")
        
        let db = Firestore.firestore()
        let listener = db.collection("chats")
            .whereField("participants", arrayContains: userId)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    print("❌ 聊天室監聽器錯誤: \(error)")
                } else {
                    print("📨 聊天室監聽器收到更新: \(snapshot?.documents.count ?? 0) 個聊天室")
                }
                completion(snapshot, error)
            }
        
        listeners[listenerKey] = listener
        return listenerKey
    }
    
    // MARK: - Messages Listener
    func createMessagesListener(chatId: String, completion: @escaping (QuerySnapshot?, Error?) -> Void) -> String {
        let listenerKey = "messages_\(chatId)"
        
        // Remove existing listener if any
        removeListener(for: listenerKey)
        
        let db = Firestore.firestore()
        let listener = db.collection("chats").document(chatId).collection("messages")
            .order(by: "timestamp", descending: false)
            .addSnapshotListener(completion)
        
        listeners[listenerKey] = listener
        return listenerKey
    }
    
    // MARK: - Remove Listeners
    func removeListener(for key: String) {
        if let listener = listeners[key] {
            listener.remove()
            listeners.removeValue(forKey: key)
        }
    }
    
    func removeAllListeners(for userId: String) {
        let userListeners = listeners.filter { $0.key.contains(userId) }
        for (key, listener) in userListeners {
            listener.remove()
            listeners.removeValue(forKey: key)
        }
    }
    
    func removeAllListeners() {
        for (_, listener) in listeners {
            listener.remove()
        }
        listeners.removeAll()
    }
}