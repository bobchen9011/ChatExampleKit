import Foundation
import FirebaseFirestore
import FirebaseAuth
import UIKit

internal class MessageViewModel: ObservableObject {
    @Published var chatRooms: [ChatRoom] = []
    @Published var messages: [Message] = []
    private var chatListenerKey: String?
    private var messageListenerKey: String?
    private let listenerManager = FirestoreListenerManager.shared
    
    func fetchChatRooms(for userId: String) {
        // 移除舊的監聽器
        if let key = chatListenerKey {
            chatListenerKey = nil
        }
        
        // 使用集中管理的監聽器
        chatListenerKey = listenerManager.createChatRoomListener(userId: userId) { snapshot, error in
            if let error = error {
                print("❌ 獲取聊天室失敗: \(error)")
                return
            }
            
            guard let documents = snapshot?.documents else { 
                print("⚠️ 沒有找到聊天室")
                DispatchQueue.main.async {
                    self.chatRooms = []
                }
                return 
            }
            
            print("✅ 收到聊天室更新 - 文檔數量: \(documents.count)")
            
            // 處理每個聊天室並計算未讀數量
            var updatedChatRooms: [ChatRoom] = []
            let dispatchGroup = DispatchGroup()
            
            for document in documents {
                if var chatRoom = try? document.data(as: ChatRoom.self) {
                    chatRoom.id = document.documentID
                    
                    // 異步計算未讀數量
                    dispatchGroup.enter()
                    self.calculateUnreadCount(for: document.documentID, currentUserId: userId) { unreadCount in
                        chatRoom.unreadCount = unreadCount
                        updatedChatRooms.append(chatRoom)
                        dispatchGroup.leave()
                    }
                }
            }
            
            // 等待所有未讀數量計算完成後更新UI
            dispatchGroup.notify(queue: .main) {
                // 排序，確保最新的訊息在前面
                let sortedChatRooms = updatedChatRooms.sorted {
                    ($0.lastTimestamp ?? Date.distantPast) > ($1.lastTimestamp ?? Date.distantPast)
                }
                
                print("📱 更新聊天室列表 - 數量: \(sortedChatRooms.count)")
                for room in sortedChatRooms {
                    print("  - 聊天室: \(room.id ?? "無ID"), 未讀: \(room.unreadCount), 最後訊息: \(room.lastMessage ?? "無")")
                }
                
                self.chatRooms = sortedChatRooms
            }
        }
    }
    
    func fetchMessages(for chatId: String) {
        print("開始獲取聊天記錄 - chatId: \(chatId)")
        
        // 移除舊的監聽器
        if let key = messageListenerKey {
            messageListenerKey = nil
        }
        
        // 先同步獲取現有消息
        loadExistingMessages(for: chatId)
        
        // 然後設置監聽器獲取實時更新
        messageListenerKey = listenerManager.createMessagesListener(chatId: chatId) { snapshot, error in
            if let error = error {
                print("❌ 監聽訊息失敗: \(error)")
                print("錯誤詳情: \(error.localizedDescription)")
                return
            }
            
            guard let documents = snapshot?.documents else {
                print("⚠️ 沒有收到訊息文檔")
                return 
            }
            
            DispatchQueue.main.async {
                let newMessages = documents.compactMap { try? $0.data(as: Message.self) }
                print("✅ 監聽器更新：收到 \(newMessages.count) 條訊息")
                self.messages = newMessages
            }
        }
    }
    
    /// 同步獲取現有消息
    private func loadExistingMessages(for chatId: String) {
        print("🔍 開始同步獲取歷史訊息 - chatId: \(chatId)")
        
        // 檢查用戶認證狀態
        guard let currentUser = Auth.auth().currentUser else {
            print("❌ 用戶未登入，無法獲取歷史訊息")
            return
        }
        
        print("✅ 用戶已認證: \(currentUser.uid)")
        
        let db = Firestore.firestore()
        
        db.collection("chats").document(chatId).collection("messages")
            .order(by: "timestamp", descending: false)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("❌ 同步獲取消息失敗: \(error)")
                    print("錯誤詳情: \(error.localizedDescription)")
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    print("⚠️ 沒有找到歷史訊息文檔")
                    return
                }
                
                let existingMessages = documents.compactMap { try? $0.data(as: Message.self) }
                print("✅ 同步載入歷史訊息：\(existingMessages.count) 條")
                
                DispatchQueue.main.async {
                    self.messages = existingMessages
                }
            }
    }
    
    func sendMessage(chatId: String, text: String, senderId: String) {
        print("開始發送訊息 - chatId: \(chatId), text: \(text), senderId: \(senderId)")
        
        // 檢查用戶認證狀態
        guard let currentUser = Auth.auth().currentUser else {
            print("❌ 用戶未登入，無法發送訊息")
            return
        }
        
        print("✅ 用戶已認證: \(currentUser.uid)")
        
        // 檢查聊天室的 participants 設定
        let db = Firestore.firestore()
        db.collection("chats").document(chatId).getDocument { document, error in
            if let error = error {
                print("❌ 獲取聊天室資料失敗: \(error)")
            } else if let document = document, document.exists {
                let participants = document.data()?["participants"] as? [String] ?? []
                print("📋 聊天室參與者: \(participants)")
                print("🔍 當前用戶是否在參與者中: \(participants.contains(currentUser.uid))")
            } else {
                print("❌ 聊天室文檔不存在")
            }
        }
        
        let currentTime = Date()
        let message = Message(
            id: nil, 
            chatId: chatId, 
            senderId: senderId, 
            content: text, 
            timestamp: currentTime, 
            isRead: false
        )
        
        do {
            let documentRef = try db.collection("chats").document(chatId).collection("messages").addDocument(from: message) { error in
                if let error = error {
                    print("❌ 添加訊息到 Firestore 失敗: \(error)")
                    print("錯誤詳情: \(error.localizedDescription)")
                } else {
                    print("✅ 訊息已成功添加到 Firestore")
                }
            }
            print("📝 訊息文檔 ID: \(documentRef.documentID)")
            
            // 更新聊天室最後訊息
            let updateData: [String: Any] = [
                "lastMessage": text,
                "lastTimestamp": currentTime,
                "lastMessageSenderId": senderId,
                "lastMessageIsRead": false
            ]
            
            db.collection("chats").document(chatId).setData(updateData, merge: true) { error in
                if let error = error {
                    print("❌ 更新聊天室文檔失敗: \(error)")
                    print("錯誤詳情: \(error.localizedDescription)")
                } else {
                    print("✅ 聊天室文檔更新成功")
                }
            }
        } catch {
            print("❌ 發送訊息異常: \(error)")
            print("異常詳情: \(error.localizedDescription)")
        }
    }
    
    func createOrGetChatRoom(userId1: String, userId2: String, completion: @escaping (String, Bool) -> Void) {
        let db = Firestore.firestore()
        let participants = [userId1, userId2].sorted()
        
        print("🔍 查找或創建聊天室 - userId1: \(userId1), userId2: \(userId2)")
        print("📋 participants陣列: \(participants)")
        
        // 查找包含兩個參與者的聊天室
        db.collection("chats")
            .whereField("participants", arrayContains: userId1)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("查詢聊天室失敗: \(error)")
                    self.createNewChatRoom(participants: participants, completion: completion)
                    return
                }
                
                // 在結果中尋找包含兩個參與者的聊天室
                let existingChat = snapshot?.documents.first { document in
                    if let chatRoom = try? document.data(as: ChatRoom.self) {
                        return chatRoom.participants.contains(userId1) && 
                               chatRoom.participants.contains(userId2) &&
                               chatRoom.participants.count == 2
                    }
                    return false
                }
                
                if let existingChat = existingChat {
                    completion(existingChat.documentID, false)
                } else {
                    self.createNewChatRoom(participants: participants, completion: completion)
                }
            }
    }
    
    private func createNewChatRoom(participants: [String], completion: @escaping (String, Bool) -> Void) {
        let db = Firestore.firestore()
        
        print("🔧 創建新聊天室 - participants: \(participants)")
        
        let chatRoom = ChatRoom(
            id: nil,
            participants: participants,
            lastMessage: nil,
            lastTimestamp: nil
        )
        
        do {
            let ref = try db.collection("chats").addDocument(from: chatRoom)
            print("✅ 聊天室創建成功: \(ref.documentID)")
            
            // 驗證創建的聊天室資料
            ref.getDocument { document, error in
                if let error = error {
                    print("❌ 獲取聊天室資料失敗: \(error)")
                } else if let document = document, document.exists {
                    let data = document.data()
                    print("📋 創建的聊天室資料: \(data ?? [:])")
                } else {
                    print("⚠️ 聊天室文檔不存在")
                }
            }
            
            completion(ref.documentID, true)
        } catch {
            print("❌ 創建聊天室異常: \(error)")
        }
    }
    
    // 計算未讀訊息數量
    private func calculateUnreadCount(for chatId: String, currentUserId: String, completion: @escaping (Int) -> Void) {
        let db = Firestore.firestore()
        db.collection("chats").document(chatId).collection("messages")
            .whereField("isRead", isEqualTo: false)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("❌ 計算未讀訊息數量時發生錯誤: \(error)")
                    completion(0)
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    completion(0)
                    return
                }
                
                // 手動過濾不是當前用戶發送的未讀訊息
                let unreadMessages = documents.filter { document in
                    if let senderId = document.data()["senderId"] as? String {
                        return senderId != currentUserId
                    }
                    return false
                }
                
                let unreadCount = unreadMessages.count
                completion(unreadCount)
            }
    }
    
    // 獲取用戶資料
    func fetchUserData(for userId: String, completion: @escaping (User?) -> Void) {
        let db = Firestore.firestore()
        db.collection("users").document(userId).getDocument { snapshot, error in
            if let error = error {
                print("獲取用戶資料失敗: \(error)")
                completion(nil)
                return
            }
            let user = try? snapshot?.data(as: User.self)
            completion(user)
        }
    }
    
    // 標記訊息為已讀
    func markMessagesAsRead(chatId: String, currentUserId: String) {
        print("開始標記訊息為已讀 - chatId: \(chatId)")
        let db = Firestore.firestore()
        
        let batch = db.batch()
        var hasUnreadFromOthers = false
        
        db.collection("chats").document(chatId).collection("messages")
            .whereField("isRead", isEqualTo: false)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("查詢未讀訊息時發生錯誤: \(error)")
                    return
                }
                
                guard let documents = snapshot?.documents else { 
                    print("沒有未讀訊息")
                    self.updateChatRoomReadStatus(chatId: chatId, currentUserId: currentUserId)
                    return 
                }
                
                for doc in documents {
                    if let senderId = doc.data()["senderId"] as? String, senderId != currentUserId {
                        hasUnreadFromOthers = true
                        batch.updateData(["isRead": true], forDocument: doc.reference)
                    }
                }
                
                if hasUnreadFromOthers {
                    batch.commit { error in
                        if let error = error {
                            print("批次更新訊息為已讀時發生錯誤: \(error)")
                        } else {
                            print("成功標記所有未讀訊息為已讀")
                            self.updateChatRoomReadStatus(chatId: chatId, currentUserId: currentUserId)
                        }
                    }
                } else {
                    self.updateChatRoomReadStatus(chatId: chatId, currentUserId: currentUserId)
                }
            }
    }
    
    // 更新聊天室的已讀狀態
    private func updateChatRoomReadStatus(chatId: String, currentUserId: String) {
        let db = Firestore.firestore()
        
        db.collection("chats").document(chatId).getDocument { snapshot, error in
            if let error = error {
                print("獲取聊天室資料時發生錯誤: \(error)")
                return
            }
            
            guard let chatData = snapshot?.data() else {
                print("無法獲取聊天室資料")
                return
            }
            
            let lastMessageSenderId = chatData["lastMessageSenderId"] as? String
            let lastMessageIsRead = chatData["lastMessageIsRead"] as? Bool ?? false
            
            // 只有當最後一筆訊息不是當前用戶發送且未讀時，才更新
            if let senderId = lastMessageSenderId,
               senderId != currentUserId,
               !lastMessageIsRead {
                
                db.collection("chats").document(chatId).updateData([
                    "lastMessageIsRead": true
                ]) { error in
                    if let error = error {
                        print("更新聊天室已讀狀態時發生錯誤: \(error)")
                    } else {
                        print("成功更新聊天室已讀狀態")
                    }
                }
            }
        }
    }
    
    func cleanup() {
        chatListenerKey = nil
        messageListenerKey = nil
        chatRooms.removeAll()
        messages.removeAll()
    }
    
    func removeAllListeners(for userId: String) {
        listenerManager.removeAllListeners(for: userId)
        cleanup()
    }
    
    // MARK: - 圖片訊息功能
    
    /// 發送圖片訊息
    func sendImageMessage(chatId: String, image: UIImage, caption: String, senderId: String) {
        print("🖼️ 開始發送圖片訊息 - chatId: \(chatId), caption: \(caption)")
        
        let db = Firestore.firestore()
        let currentTime = Date()
        let messageId = UUID().uuidString
        
        // 壓縮圖片
        guard let imageData = CloudinaryService.shared.compressImage(image) else {
            print("❌ 圖片壓縮失敗")
            return
        }
        
        // 先創建帶有本地路徑的訊息
        let localPath = saveImageLocally(imageData: imageData, messageId: messageId)
        let messageType: MessageType = caption.isEmpty ? .image : .imageWithText
        
        var message = Message(
            id: messageId,
            chatId: chatId,
            senderId: senderId,
            content: caption,
            timestamp: currentTime,
            isRead: false,
            messageType: messageType,
            imageLocalPath: localPath,
            uploadStatus: .uploading
        )
        
        // 計算圖片尺寸
        message.imageSize = ImageSize(width: Double(image.size.width), height: Double(image.size.height))
        
        // 先保存到 Firestore（顯示上傳中狀態）
        do {
            try db.collection("chats").document(chatId).collection("messages").document(messageId).setData(from: message)
            print("✅ 圖片訊息已添加到 Firestore（上傳中）")
            
            // 更新聊天室最後訊息
            let lastMessageText = caption.isEmpty ? "📷 圖片" : "📷 \(caption)"
            updateChatRoomLastMessage(chatId: chatId, message: lastMessageText, timestamp: currentTime, senderId: senderId)
            
            // 開始上傳到 Cloudinary
            uploadImageToCloudinary(imageData: imageData, messageId: messageId, chatId: chatId)
            
        } catch {
            print("❌ 保存圖片訊息到 Firestore 失敗: \(error)")
        }
    }
    
    
    /// 保存圖片到本地
    private func saveImageLocally(imageData: Data, messageId: String) -> String? {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let imagePath = documentsPath.appendingPathComponent("chat_images").appendingPathComponent("\(messageId).jpg")
        
        do {
            // 創建目錄（如果不存在）
            try FileManager.default.createDirectory(at: imagePath.deletingLastPathComponent(), withIntermediateDirectories: true)
            
            // 保存文件
            try imageData.write(to: imagePath)
            print("💾 圖片已保存到本地: \(imagePath.path)")
            return imagePath.path
        } catch {
            print("❌ 保存圖片到本地失敗: \(error)")
            return nil
        }
    }
    
    /// 上傳圖片到 Cloudinary
    private func uploadImageToCloudinary(imageData: Data, messageId: String, chatId: String) {
        print("☁️ 開始上傳圖片到 Cloudinary...")
        
        let fileName = "\(chatId)_\(messageId)"
        
        CloudinaryService.shared.uploadImage(
            imageData: imageData,
            fileName: fileName,
            folder: "chat_images"
        ) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let imageUrl):
                    print("✅ Cloudinary 上傳成功: \(imageUrl)")
                    self?.updateImageMessageUploadStatus(
                        chatId: chatId,
                        messageId: messageId,
                        status: .completed,
                        imageUrl: imageUrl
                    )
                    
                case .failure(let error):
                    print("❌ Cloudinary 上傳失敗: \(error.localizedDescription)")
                    self?.updateImageMessageUploadStatus(
                        chatId: chatId,
                        messageId: messageId,
                        status: .failed,
                        imageUrl: nil
                    )
                }
            }
        }
    }
    
    /// 更新圖片訊息的上傳狀態
    private func updateImageMessageUploadStatus(chatId: String, messageId: String, status: ImageUploadStatus, imageUrl: String?) {
        let db = Firestore.firestore()
        
        var updateData: [String: Any] = [
            "uploadStatus": status.rawValue
        ]
        
        if let imageUrl = imageUrl {
            updateData["imageUrl"] = imageUrl
        }
        
        db.collection("chats").document(chatId).collection("messages").document(messageId).updateData(updateData) { error in
            if let error = error {
                print("❌ 更新圖片訊息狀態失敗: \(error)")
            } else {
                print("✅ 圖片訊息狀態已更新: \(status)")
            }
        }
    }
    
    /// 更新聊天室最後訊息
    private func updateChatRoomLastMessage(chatId: String, message: String, timestamp: Date, senderId: String) {
        let db = Firestore.firestore()
        let updateData: [String: Any] = [
            "lastMessage": message,
            "lastTimestamp": timestamp,
            "lastMessageSenderId": senderId,
            "lastMessageIsRead": false
        ]
        
        db.collection("chats").document(chatId).setData(updateData, merge: true) { error in
            if let error = error {
                print("❌ 更新聊天室文檔失敗: \(error)")
            } else {
                print("✅ 聊天室文檔更新成功")
            }
        }
    }
    
    // MARK: - 數據處理邏輯
    
    /// 檢查是否為訊息組的最後一條
    func isLastMessageInGroup(at index: Int) -> Bool {
        if index == messages.count - 1 { return true }
        let currentMessage = messages[index]
        let nextMessage = messages[index + 1]
        
        if currentMessage.senderId != nextMessage.senderId {
            return true
        }
        
        let timeInterval = nextMessage.timestamp.timeIntervalSince(currentMessage.timestamp)
        return timeInterval > 60
    }
    
    /// 格式化日期顯示
    func formatDate(_ date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()
        
        if calendar.isDate(date, inSameDayAs: now) {
            return "今天"
        } else if calendar.isDate(date, inSameDayAs: calendar.date(byAdding: .day, value: -1, to: now) ?? now) {
            return "昨天"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy年MM月dd日"
            return formatter.string(from: date)
        }
    }
    
    /// 檢查是否需要顯示日期分隔線
    func shouldShowDateSeparator(at index: Int) -> Bool {
        if index == 0 { return true }
        let currentMessage = messages[index]
        let previousMessage = messages[index - 1]
        
        let calendar = Calendar.current
        return !calendar.isDate(currentMessage.timestamp, inSameDayAs: previousMessage.timestamp)
    }
    
    /// 檢查是否應該顯示已讀狀態（只對最新訊息組的最後一條顯示）
    func shouldShowReadStatus(at index: Int, currentUserId: String) -> Bool {
        // 只對自己發送的訊息顯示已讀狀態
        guard messages[index].senderId == currentUserId else { return false }
        
        // 必須是該訊息組的最後一條
        guard isLastMessageInGroup(at: index) else { return false }
        
        // 檢查是否是所有自己發送訊息中的最新一組
        let currentMessage = messages[index]
        let myMessages = messages.filter { $0.senderId == currentUserId }
        
        // 找到最新的訊息組
        guard let latestMyMessage = myMessages.last else { return false }
        
        // 如果當前訊息就是最新訊息，或者與最新訊息在同一組內，則顯示已讀
        let timeDifference = latestMyMessage.timestamp.timeIntervalSince(currentMessage.timestamp)
        return timeDifference <= 60 // 1分鐘內視為同一組
    }
}
