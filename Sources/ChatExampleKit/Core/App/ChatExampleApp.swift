//
//  ChatExampleApp.swift
//  ChatExample
//
//  Created by BBOB on 2025/9/1.
//

import SwiftUI
import Firebase
import GoogleSignIn

@main
internal struct ChatExampleApp: App {
    @StateObject private var authViewModel = AuthViewModel()
    
    init() {
        // Configure Firebase
        FirebaseApp.configure()
        
        // Configure App Appearance
        configureAppAppearance()
    }
    
    var body: some Scene {
        WindowGroup {
            Group {
                if authViewModel.isAuthenticated {
                    MainTabView()
                        .environmentObject(authViewModel)
                } else {
                    LoginView()
                        .environmentObject(authViewModel)
                }
            }
        }
    }
    
    // MARK: - App Appearance Configuration
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
