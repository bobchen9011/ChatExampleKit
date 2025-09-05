//
//  ChatListView.swift
//  ChatExampleKit
//
//  主入口點 - 用戶只需使用這個 View 即可擁有完整聊天功能
//

import SwiftUI

/// ChatListView - 聊天應用的主入口點
///
/// 用戶只需要導入 ChatExampleKit 並使用這個 View：
/// ```swift
/// import ChatExampleKit
///
/// struct ContentView: View {
///     var body: some View {
///         ChatListView()  // 擁有完整聊天功能！
///     }
/// }
/// ```
///
/// 功能包含：
/// - 身份驗證 (Google 登入)
/// - 聊天列表和聊天室
/// - 相機和圖片功能
/// - 用戶搜索
/// - 統一綠色主題
public struct ChatListView: View {
    @StateObject private var chatManager = ChatManager.shared
    
    /// 無參數初始化 - 自動配置所有功能
    public init() {}
    
    public var body: some View {
        chatManager.rootView
            .onAppear {
                chatManager.initialize()
            }
    }
}

#Preview {
    ChatListView()
}