import Foundation

// MARK: - Cloudinary 配置
internal struct CloudinaryConfig {
    
    // MARK: - 配置說明
    /*
     🔧 設置步驟：
     
     1. 註冊 Cloudinary 帳號：https://cloudinary.com/
     2. 進入 Dashboard 獲取配置信息
     3. 替換下面的配置值
     4. 設置 Upload Preset（無需簽名）
     
     📋 必要配置：
     - CLOUD_NAME: 你的雲端名稱
     - UPLOAD_PRESET: 上傳預設名稱（建議設為 unsigned）
     - API_KEY: API 金鑰（可選，用於管理功能）
     
     ⚠️ 安全提醒：
     - 不要將 API Secret 放在客戶端代碼中
     - 使用 unsigned upload preset 進行客戶端上傳
     */
    
    // MARK: - 配置常數
    
    /// Cloudinary 雲端名稱
    /// 在 Cloudinary Dashboard 可以找到
    static let cloudName = "dpxp3abrf" // 🔴 請替換成你的 cloud name
    
    /// 上傳預設名稱
    /// 在 Cloudinary Dashboard > Settings > Upload 中創建
    /// 建議設為 "unsigned" 類型，允許客戶端直接上傳
    static let uploadPreset = "unsigned_ios" // 🔴 請替換成你的 upload preset
    
    /// API 金鑰（可選）
    /// 在 Cloudinary Dashboard 可以找到
    static let apiKey = "576995438639923" // 🔴 請替換成你的 API key
    
    // MARK: - 運行時檢查
    
    /// 檢查配置是否完整
    static var isConfigured: Bool {
        return cloudName != "YOUR_CLOUD_NAME" &&
               uploadPreset != "YOUR_UPLOAD_PRESET" &&
               !cloudName.isEmpty &&
               !uploadPreset.isEmpty
    }
    
    /// 獲取上傳 URL
    static var uploadURL: String {
        return "https://api.cloudinary.com/v1_1/\(cloudName)/image/upload"
    }
    
    /// 配置狀態描述
    static var configurationStatus: String {
        if isConfigured {
            return "✅ Cloudinary 配置已完成"
        } else {
            return "❌ Cloudinary 配置未完成，請在 CloudinaryConfig.swift 中設置正確的配置"
        }
    }
}

// MARK: - 使用示例
/*
 🔧 設置步驟詳解：
 
 1️⃣ 註冊 Cloudinary：
    訪問 https://cloudinary.com/ 並註冊免費帳號
 
 2️⃣ 獲取 Cloud Name：
    登入後在 Dashboard 首頁可以看到 "Cloud name"
    例如：my-app-cloud
 
 3️⃣ 創建 Upload Preset：
    - 進入 Settings > Upload 
    - 點擊 "Add upload preset"
    - 設置名稱，例如：chat_images_upload
    - 設置 Signing Mode 為 "Unsigned"
    - 可設置 Folder 為 "chat_images"（可選）
    - 保存設置
 
 4️⃣ 替換配置：
    將上面的配置值替換為你的實際值：
    ```swift
    static let cloudName = "my-app-cloud"
    static let uploadPreset = "chat_images_upload"
    static let apiKey = "123456789012345" // 可選
    ```
 
 5️⃣ 測試上傳：
    運行應用並嘗試發送圖片訊息
 */
