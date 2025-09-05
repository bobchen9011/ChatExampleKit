import SwiftUI

internal struct DateSeparatorView: View {
    let date: Date
    let messageViewModel: MessageViewModel
    
    var body: some View {
        HStack {
            Spacer()
            Text(messageViewModel.formatDate(date))
                .font(.caption)
                .foregroundColor(.gray)
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(Color.appCardGreen)
                .cornerRadius(12)
            Spacer()
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    VStack(spacing: 16) {
        DateSeparatorView(
            date: Date(),
            messageViewModel: MessageViewModel()
        )
        
        DateSeparatorView(
            date: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date(),
            messageViewModel: MessageViewModel()
        )
        
        DateSeparatorView(
            date: Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date(),
            messageViewModel: MessageViewModel()
        )
    }
    .padding()
    .background(Color.appBackgroundGreen)
}