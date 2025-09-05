# ChatExampleKit

一個完整的 iOS 聊天應用 Swift Package，讓您只需一行代碼即可擁有企業級聊天功能。

## ✨ 特點

- 🚀 **一行代碼使用**: `ChatListView()` 即可擁有完整聊天 App
- 🔐 **身份驗證**: 內建 Google 登入系統
- 💬 **完整聊天**: 即時聊天室和訊息系統
- 📷 **多媒體支援**: 相機拍照和圖片選擇功能
- 👥 **用戶管理**: 用戶搜索和好友系統
- 🎨 **精美主題**: 統一的綠色主題設計
- ⚡ **零配置**: 自動初始化所有服務

## 📱 功能預覽

| 身份驗證 | 聊天列表 | 聊天室 | 用戶搜索 |
|---------|---------|--------|----------|
| Google登入 | 對話列表 | 即時聊天 | 查找用戶 |
| 自動註冊 | 最新訊息 | 圖片傳送 | 開始對話 |

## 🚀 快速開始

### 1. 安裝

#### Swift Package Manager
```swift
dependencies: [
    .package(url: "https://github.com/yourusername/ChatExampleKit", from: "1.0.0")
]
```

#### Xcode
1. File → Add Package Dependencies
2. 輸入: `https://github.com/yourusername/ChatExampleKit`
3. 選擇版本並添加到項目

### 2. 使用

```swift
import SwiftUI
import ChatExampleKit

@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            ChatListView()  // 🎉 完成！擁有完整聊天功能
        }
    }
}
```

就是這麼簡單！無需任何配置，無需學習複雜的 API。

## 🛠️ 高級配置 (可選)

如果您需要使用自己的 Firebase 項目：

1. **添加 Firebase 配置**
   將您的 `GoogleService-Info.plist` 添加到主應用 Bundle

2. **配置權限**
   在 `Info.plist` 中添加：
   ```xml
   <key>NSCameraUsageDescription</key>
   <string>需要相機權限來拍攝和傳送照片</string>
   <key>NSPhotoLibraryUsageDescription</key>
   <string>需要相片庫權限來選擇和傳送圖片</string>
   ```

## 🏗️ 架構設計

ChatExampleKit 採用現代化的模組化 MVVM 架構：

```
ChatExampleKit/
├── 🎯 ChatListView          # 公開接口 - 用戶只需這一個
├── 🧠 ChatManager           # 核心管理器 - 統一服務管理
├── 🏗️ Core/                 # 核心服務
│   ├── Models/             # 數據模型
│   ├── Services/           # Firebase、雲端服務
│   └── Config/             # 配置管理
├── ✨ Features/             # 功能模組
│   ├── Authentication/     # 身份驗證
│   ├── Chat/              # 聊天功能
│   ├── Camera/            # 相機功能
│   └── UserSearch/        # 用戶搜索
└── 🎨 Shared/              # 共用組件
    ├── Theme/             # 主題系統
    └── Components/        # UI 組件
```

## 🔧 內建功能

### 身份驗證
- ✅ Google 登入整合
- ✅ 自動用戶註冊
- ✅ 登入狀態管理
- ✅ 安全登出功能

### 聊天系統
- ✅ 即時訊息傳送
- ✅ 圖片訊息支援
- ✅ 訊息狀態顯示
- ✅ 聊天室管理

### 多媒體功能
- ✅ 相機拍照
- ✅ 相片庫選擇
- ✅ 圖片預覽和裁剪
- ✅ 雲端儲存整合

### 用戶系統
- ✅ 用戶搜索
- ✅ 個人資料管理
- ✅ 好友添加
- ✅ 在線狀態

## 📋 系統要求

- **iOS**: 15.0+
- **Xcode**: 14.0+
- **Swift**: 5.9+

## 🔒 依賴項

- Firebase SDK (身份驗證、資料庫、儲存)
- Google Sign-In SDK (登入系統)

所有依賴項都會自動管理，無需手動配置。

## 🤝 對比其他方案

| 特性 | ChatExampleKit | 其他聊天SDK |
|------|----------------|------------|
| **使用複雜度** | 一行代碼 | 複雜配置 |
| **功能完整度** | 完整應用級 | 僅UI組件 |
| **自動配置** | ✅ 全自動 | ❌ 需手動 |
| **主題統一** | ✅ 內建主題 | ❌ 需自定義 |
| **身份驗證** | ✅ 內建Google | ❌ 需另外整合 |
| **多媒體** | ✅ 完整支援 | ❌ 部分支援 |

## 🎯 適用場景

- ✅ **快速原型開發**: 需要快速驗證聊天功能
- ✅ **MVP 產品**: 創業項目需要完整聊天系統
- ✅ **企業應用**: 內部通訊工具開發
- ✅ **學習項目**: 了解現代 iOS 聊天應用架構
- ✅ **時間緊迫**: 需要在短時間內實現聊天功能

## 📚 更多示例

查看 [Examples/](Examples/) 目錄中的完整示例項目和使用指南。

## 🐛 問題反饋

如果您遇到任何問題或有建議改進，請創建 Issue 或 Pull Request。

## 📄 授權

MIT License - 詳見 [LICENSE](LICENSE) 文件。

---

**ChatExampleKit** - 讓聊天功能開發變得簡單 🚀