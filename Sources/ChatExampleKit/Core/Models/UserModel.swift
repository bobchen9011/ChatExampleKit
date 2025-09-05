import Foundation
import FirebaseFirestore

// MARK: - User Model
internal struct User: Identifiable, Codable {
    @DocumentID var id: String?
    var username: String
    var email: String
    var profileImageUrl: String?
    var createdAt: Date = Date()
}