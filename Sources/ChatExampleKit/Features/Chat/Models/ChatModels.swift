import Foundation
import FirebaseFirestore

// MARK: - ChatRoom Model
internal struct ChatRoom: Identifiable, Codable {
    @DocumentID var id: String?
    var participants: [String]
    var lastMessage: String?
    var lastTimestamp: Date?
    var lastMessageSenderId: String?
    var lastMessageIsRead: Bool = false
    var unreadCount: Int = 0
}

// MARK: - Message Model
internal struct Message: Identifiable, Codable {
    @DocumentID var id: String?
    var chatId: String
    var senderId: String
    var content: String
    var timestamp: Date
    var isRead: Bool
    var messageType: MessageType = .text
    var imageUrl: String?
    var imageLocalPath: String?
    var imageSize: ImageSize?
    var uploadStatus: ImageUploadStatus = .none
    
    var isImageMessage: Bool {
        return messageType == .image || messageType == .imageWithText
    }
    
    var hasTextContent: Bool {
        return !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

// MARK: - Message Type
internal enum MessageType: String, Codable, CaseIterable {
    case text = "text"
    case image = "image"
    case imageWithText = "image_with_text"
}