import Foundation
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Cloudinary 上傳服務
internal class CloudinaryService {
    static let shared = CloudinaryService()
    
    // 使用配置文件中的設置
    private let cloudName = CloudinaryConfig.cloudName
    private let uploadPreset = CloudinaryConfig.uploadPreset
    private let apiKey = CloudinaryConfig.apiKey
    
    private init() {}
    
    /// 上傳圖片到 Cloudinary
    /// - Parameters:
    ///   - imageData: 圖片數據
    ///   - fileName: 文件名稱
    ///   - folder: 上傳資料夾路徑（可選）
    ///   - completion: 完成回調 (成功時返回 URL，失敗時返回錯誤)
    func uploadImage(
        imageData: Data,
        fileName: String,
        folder: String? = "chat_images",
        completion: @escaping (Result<String, CloudinaryError>) -> Void
    ) {
        // 檢查配置（添加詳細調試信息）
        print("🔍 Cloudinary 配置檢查:")
        print("   - cloudName: '\(cloudName)'")
        print("   - uploadPreset: '\(uploadPreset)'")
        print("   - isConfigured: \(CloudinaryConfig.isConfigured)")
        
        guard CloudinaryConfig.isConfigured else {
            print("❌ \(CloudinaryConfig.configurationStatus)")
            completion(.failure(.configurationError(CloudinaryConfig.configurationStatus)))
            return
        }
        
        let uploadURL = "https://api.cloudinary.com/v1_1/\(cloudName)/image/upload"
        
        guard let url = URL(string: uploadURL) else {
            completion(.failure(.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        // 添加 upload_preset
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"upload_preset\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(uploadPreset)\r\n".data(using: .utf8)!)
        
        // 添加文件夾（如果指定）
        if let folder = folder {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"folder\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(folder)\r\n".data(using: .utf8)!)
        }
        
        // 添加文件名
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"public_id\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(fileName)\r\n".data(using: .utf8)!)
        
        // 添加圖片數據
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(fileName).jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n".data(using: .utf8)!)
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        print("☁️ 開始上傳圖片到 Cloudinary - 文件名: \(fileName)")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("❌ Cloudinary 上傳網路錯誤: \(error)")
                completion(.failure(.networkError(error)))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(.invalidResponse))
                return
            }
            
            guard let data = data else {
                completion(.failure(.noData))
                return
            }
            
            print("📤 Cloudinary 回應狀態碼: \(httpResponse.statusCode)")
            
            if httpResponse.statusCode == 200 {
                // 解析成功回應
                do {
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let secureUrl = json["secure_url"] as? String {
                        print("✅ Cloudinary 上傳成功: \(secureUrl)")
                        completion(.success(secureUrl))
                    } else {
                        print("❌ Cloudinary 回應格式錯誤")
                        completion(.failure(.invalidResponseFormat))
                    }
                } catch {
                    print("❌ Cloudinary JSON 解析錯誤: \(error)")
                    completion(.failure(.jsonParsingError(error)))
                }
            } else {
                // 處理錯誤回應
                do {
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let errorInfo = json["error"] as? [String: Any],
                       let message = errorInfo["message"] as? String {
                        print("❌ Cloudinary 上傳失敗: \(message)")
                        completion(.failure(.uploadError(message)))
                    } else {
                        print("❌ Cloudinary 上傳失敗，狀態碼: \(httpResponse.statusCode)")
                        completion(.failure(.httpError(httpResponse.statusCode)))
                    }
                } catch {
                    print("❌ Cloudinary 錯誤回應解析失敗")
                    completion(.failure(.httpError(httpResponse.statusCode)))
                }
            }
        }.resume()
    }
    
#if canImport(UIKit)
    /// 壓縮圖片
    /// - Parameters:
    ///   - image: 原始圖片
    ///   - maxSizeKB: 最大文件大小（KB）
    /// - Returns: 壓縮後的圖片數據
    func compressImage(_ image: UIImage, maxSizeKB: Int = 800) -> Data? {
        let maxBytes = maxSizeKB * 1024
        var compression: CGFloat = 0.9
        var imageData = image.jpegData(compressionQuality: compression)
        
        // 逐步降低質量直到達到目標大小
        while let data = imageData, data.count > maxBytes && compression > 0.1 {
            compression -= 0.1
            imageData = image.jpegData(compressionQuality: compression)
        }
        
        print("📦 圖片壓縮完成 - 原始大小: \(image.size), 壓縮率: \(compression), 文件大小: \((imageData?.count ?? 0) / 1024)KB")
        return imageData
    }
#endif
}

// MARK: - Cloudinary 錯誤類型
internal enum CloudinaryError: Error, LocalizedError {
    case configurationError(String)
    case invalidURL
    case networkError(Error)
    case invalidResponse
    case noData
    case invalidResponseFormat
    case jsonParsingError(Error)
    case uploadError(String)
    case httpError(Int)
    
    var errorDescription: String? {
        switch self {
        case .configurationError(let message):
            return "配置錯誤: \(message)"
        case .invalidURL:
            return "無效的 URL"
        case .networkError(let error):
            return "網路錯誤: \(error.localizedDescription)"
        case .invalidResponse:
            return "無效的回應"
        case .noData:
            return "沒有數據"
        case .invalidResponseFormat:
            return "回應格式錯誤"
        case .jsonParsingError(let error):
            return "JSON 解析錯誤: \(error.localizedDescription)"
        case .uploadError(let message):
            return "上傳錯誤: \(message)"
        case .httpError(let code):
            return "HTTP 錯誤: \(code)"
        }
    }
}