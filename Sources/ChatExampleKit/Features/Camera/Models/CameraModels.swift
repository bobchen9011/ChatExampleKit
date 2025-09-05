import Foundation

// MARK: - Image Size Model
internal struct ImageSize: Codable {
    var width: Double
    var height: Double
    
    func scaledSize(maxWidth: Double, maxHeight: Double) -> ImageSize {
        let aspectRatio = width / height
        
        if width <= maxWidth && height <= maxHeight {
            return self
        }
        
        let scaledByWidth = ImageSize(width: maxWidth, height: maxWidth / aspectRatio)
        let scaledByHeight = ImageSize(width: maxHeight * aspectRatio, height: maxHeight)
        
        if scaledByWidth.height <= maxHeight {
            return scaledByWidth
        } else {
            return scaledByHeight
        }
    }
}

// MARK: - Image Upload Status
internal enum ImageUploadStatus: String, Codable {
    case none = "none"
    case uploading = "uploading"
    case completed = "completed"
    case failed = "failed"
}