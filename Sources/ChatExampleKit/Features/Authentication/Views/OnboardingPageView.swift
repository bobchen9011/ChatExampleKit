//
//  OnboardingPageView.swift
//  ChatExample
//
//  Created by BBOB on 2025/9/4.
//

import SwiftUI

internal struct OnboardingPageView: View {
    let page: OnboardingPage
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // 圖標
            Image(systemName: page.imageName)
                .font(.system(size: 100))
                .foregroundColor(Color.appPrimaryGreen)
                .padding(.bottom, 20)
            
            // 標題
            Text(page.title)
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(Color.appPrimaryText)
                .multilineTextAlignment(.center)
            
            // 副標題
            Text(page.subtitle)
                .font(.title2)
                .foregroundColor(Color.appHintText)
                .multilineTextAlignment(.center)
            
            // 描述
            Text(page.description)
                .font(.body)
                .foregroundColor(Color.appSecondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Spacer()
        }
    }
}

#Preview {
    OnboardingPageView(
        page: OnboardingPage(
            title: "歡迎使用聊天應用",
            subtitle: "與朋友即時聊天",
            imageName: "message.circle.fill",
            description: "開始與你的朋友們進行即時對話"
        )
    )
}
