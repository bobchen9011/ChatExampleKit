//
//  ChatManager.swift
//  ChatExampleKit
//
//  統一管理器 - 整合所有聊天功能和狀態管理
//

import SwiftUI
import Firebase
import GoogleSignIn
import Combine

/// ChatManager - 聊天應用的核心管理器
///
/// 負責：
/// - 自動初始化 Firebase 和 Google Sign-In
/// - 統一身份驗證狀態管理
/// - 智能路由 (登入/主界面切換)
/// - 主題配置
internal class ChatManager: ObservableObject {
    static let shared = ChatManager()
    
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    
    private var authViewModel: AuthViewModel?
    private var isInitialized = false
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        // 私有初始化確保單例
    }
    
    /// 初始化所有服務 - 在 ChatListView 出現時調用
    func initialize() {
        guard !isInitialized else { return }
        
        setupFirebase()
        setupAuthentication()
        setupTheme()
        
        isInitialized = true
    }
    
    /// 根視圖 - 根據身份驗證狀態決定顯示內容
    @ViewBuilder
    var rootView: some View {
        Group {
            if isAuthenticated {
                MainTabView()
                    .environmentObject(authViewModel ?? AuthViewModel())
            } else {
                LoginView()
                    .environmentObject(authViewModel ?? AuthViewModel())
            }
        }
    }
    
    // MARK: - 私有方法
    
    /// 設置 Firebase
    private func setupFirebase() {
        if FirebaseApp.app() == nil {
            // 嘗試使用包內的配置文件
            if let path = Bundle.module.path(forResource: "GoogleService-Info", ofType: "plist"),
               let options = FirebaseOptions(contentsOfFile: path) {
                FirebaseApp.configure(options: options)
            } else {
                // 使用主Bundle的配置文件（用戶提供）
                FirebaseApp.configure()
            }
        }
    }
    
    /// 設置身份驗證
    private func setupAuthentication() {
        authViewModel = AuthViewModel()
        
        // 監聽身份驗證狀態變化
        authViewModel?.$isAuthenticated
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isAuth in
                self?.isAuthenticated = isAuth
            }
            .store(in: &cancellables)
            
        authViewModel?.$currentUser
            .receive(on: DispatchQueue.main)
            .sink { [weak self] user in
                self?.currentUser = user
            }
            .store(in: &cancellables)
    }
    
    /// 配置應用外觀和主題
    private func setupTheme() {
        configureAppAppearance()
    }
    
    /// 配置應用外觀
    private func configureAppAppearance() {
        // TabBar 外觀設定
        UITabBar.appearance().backgroundColor = AppTheme.uiBackgroundGreen
        UITabBar.appearance().unselectedItemTintColor = AppTheme.uiHintText
        UITabBar.appearance().tintColor = AppTheme.uiPrimaryGreen
        
        // NavigationBar 外觀設定
        UINavigationBar.appearance().backgroundColor = AppTheme.uiBackgroundGreen
        UINavigationBar.appearance().largeTitleTextAttributes = [
            .foregroundColor: AppTheme.uiPrimaryText
        ]
        UINavigationBar.appearance().titleTextAttributes = [
            .foregroundColor: AppTheme.uiPrimaryText
        ]
        UINavigationBar.appearance().tintColor = AppTheme.uiPrimaryGreen
    }
}

