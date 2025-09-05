# ChatExampleKit 使用示例

## 快速開始

1. **在 Xcode 中創建新的 iOS 項目**

2. **添加 Swift Package 依賴**
   - 在 Xcode 中選擇 File → Add Package Dependencies
   - 輸入本地路徑或 Git URL: `/Users/bbob/Documents/ChatExampleKit`

3. **使用 ChatListView**

```swift
import SwiftUI
import ChatExampleKit

@main
struct ChatExampleDemoApp: App {
    var body: some Scene {
        WindowGroup {
            ChatListView()  // 一行代碼擁有完整聊天功能！
        }
    }
}
```

## 功能包含

- ✅ **身份驗證**: Google 登入系統
- ✅ **聊天功能**: 完整的聊天室和訊息系統  
- ✅ **相機功能**: 拍照和圖片選擇
- ✅ **用戶搜索**: 查找和添加其他用戶
- ✅ **統一主題**: 精美的綠色主題系統
- ✅ **自動配置**: Firebase 和 Google Sign-In 自動設置

## 注意事項

1. **Firebase 配置**: 如需使用自己的 Firebase 項目，請將 `GoogleService-Info.plist` 添加到主應用的 Bundle 中
2. **權限設置**: 確保在 Info.plist 中添加相機和相片庫使用權限
3. **Google Sign-In 配置**: 請在 Firebase Console 中啟用 Google 登入並配置 OAuth

## 最小系統要求

- iOS 15.0+
- Xcode 14.0+
- Swift 5.9+