import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

internal struct MessageBubbleView: View {
    let message: Message
    let hasTail: Bool
    let isCurrentUser: Bool
    let shouldShowReadStatus: Bool
    
    // Cross-platform screen width
    private var screenWidth: CGFloat {
#if canImport(UIKit)
        return UIScreen.main.bounds.width
#else
        return 400 // Fallback width for non-iOS platforms
#endif
    }
    
    // Cross-platform copy to pasteboard
    private func copyToPasteboard(_ text: String) {
#if canImport(UIKit)
        UIPasteboard.general.string = text
#else
        // macOS fallback would use NSPasteboard, but we'll skip for simplicity
        print("Copy to pasteboard: \(text)")
#endif
    }
    
    var body: some View {
        HStack(alignment: .bottom) {
            if isCurrentUser {
                Spacer()
                outgoingMessageView
            } else {
                incomingMessageView
                Spacer()
            }
        }
        .padding(.horizontal, 8)
    }
    
    // MARK: - 發送訊息視圖
    private var outgoingMessageView: some View {
        VStack(alignment: .trailing, spacing: 4) {
            if message.isImageMessage {
                ChatImageBubble(
                    message: message,
                    isIncoming: false,
                    maxWidth: screenWidth * 0.75
                )
            } else {
                textBubble(isIncoming: false)
            }
            
            if hasTail {
                messageMetadata(isCurrentUser: true)
            }
        }
        .frame(maxWidth: screenWidth * 0.75, alignment: .trailing)
    }
    
    // MARK: - 接收訊息視圖
    private var incomingMessageView: some View {
        VStack(alignment: .leading, spacing: 4) {
            if message.isImageMessage {
                ChatImageBubble(
                    message: message,
                    isIncoming: true,
                    maxWidth: screenWidth * 0.75
                )
            } else {
                textBubble(isIncoming: true)
            }
            
            if hasTail {
                messageMetadata(isCurrentUser: false)
            }
        }
        .frame(maxWidth: screenWidth * 0.75, alignment: .leading)
    }
    
    // MARK: - 文字氣泡
    private func textBubble(isIncoming: Bool) -> some View {
        Text(message.content)
            .font(.body)
            .foregroundColor(isIncoming ? .gray : .white)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                Group {
                    if isIncoming {
                        Color.white // 白色背景
                    } else {
Color.appPrimaryGreen // 亮綠色 #32CD32
                    }
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .contextMenu {
                Button("複製") {
                    copyToPasteboard(message.content)
                }
            }
    }
    
    // MARK: - 訊息元數據（時間和已讀狀態）
    private func messageMetadata(isCurrentUser: Bool) -> some View {
        HStack(spacing: 4) {
            if isCurrentUser {
                // 自己發的 → 時間 + 已讀（只在應該顯示已讀時才顯示）
                if message.isRead && shouldShowReadStatus {
                    Text("已讀")
                        .font(.caption2)
                        .foregroundColor(Color.appPrimaryGreen)
                }
                Text(message.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundColor(.gray)
            } else {
                // 別人發的 → 只顯示時間
                Text(message.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
        }
        .padding(.top, 2)
    }
}

#Preview {
    VStack(spacing: 10) {
        // 發送的文字訊息
        MessageBubbleView(
            message: Message(
                chatId: "preview",
                senderId: "current",
                content: "這是一條發送的訊息",
                timestamp: Date(),
                isRead: true
            ),
            hasTail: true,
            isCurrentUser: true,
            shouldShowReadStatus: true
        )
        
        // 接收的文字訊息
        MessageBubbleView(
            message: Message(
                chatId: "preview",
                senderId: "other",
                content: "這是一條接收的訊息",
                timestamp: Date(),
                isRead: false
            ),
            hasTail: true,
            isCurrentUser: false,
            shouldShowReadStatus: false
        )
    }
    .padding()
    .background(Color.gray.opacity(0.1))
}
