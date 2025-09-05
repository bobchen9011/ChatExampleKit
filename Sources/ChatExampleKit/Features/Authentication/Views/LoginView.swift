import SwiftUI

internal struct LoginView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var currentPage = 0
    
    let onboardingData = [
        OnboardingPage(
            title: "歡迎使用聊天應用",
            subtitle: "與朋友即時聊天",
            imageName: "message.circle.fill",
            description: "開始與你的朋友們進行即時對話"
        ),
        OnboardingPage(
            title: "簡潔易用",
            subtitle: "直覺的操作介面",
            imageName: "heart.circle.fill",
            description: "簡潔的設計讓聊天變得更加輕鬆"
        ),
        OnboardingPage(
            title: "開始聊天",
            subtitle: "立即體驗",
            imageName: "paperplane.circle.fill",
            description: "使用 Google 帳號快速登入開始聊天"
        )
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // 頁面指示器
            HStack {
                ForEach(0..<onboardingData.count, id: \.self) { index in
                    Circle()
                        .fill(index == currentPage ? Color.appPrimaryGreen : Color.gray.opacity(0.3))
                        .frame(width: 8, height: 8)
                        .animation(.easeInOut, value: currentPage)
                }
            }
            .padding(.top, 50)
            
            // 內容區域
            TabView(selection: $currentPage) {
                ForEach(0..<onboardingData.count, id: \.self) { index in
                    OnboardingPageView(page: onboardingData[index])
                        .tag(index)
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            
            // 底部按鈕區域
            VStack(spacing: 16) {
                if currentPage < onboardingData.count - 1 {
                    Button(action: {
                        withAnimation(.easeInOut) {
                            currentPage += 1
                        }
                    }) {
                        Text("下一步")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.appPrimaryGreen)
                            .cornerRadius(25)
                    }
                    
                    Button(action: {
                        withAnimation(.easeInOut) {
                            currentPage = onboardingData.count - 1
                        }
                    }) {
                        Text("跳過")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                } else {
                    GoogleSignInButton()
                        .environmentObject(authViewModel)
                }
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 50)
        }
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.appBackgroundGreen, Color.white]),
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
}

#Preview {
    LoginView()
        .environmentObject(AuthViewModel())
}
