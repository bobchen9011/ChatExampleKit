//
//  GoogleSignInButton.swift
//  ChatExample
//
//  Created by BBOB on 2025/9/4.
//

import SwiftUI

internal struct GoogleSignInButton: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        Button(action: {
            authViewModel.signInWithGoogle()
        }) {
            HStack {
                Image("GoogleLogo")
                    .resizable()
                    .scaledToFit()
                
                Text("使用 Google 登入")
                    .foregroundColor(Color.black)
                    .font(.headline)
                    .fontWeight(.medium)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(Color.white)
            .cornerRadius(25)
            .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
        }
        .disabled(authViewModel.isLoading)
        .overlay(
            Group {
                if authViewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                }
            }
        )
    }
}

#Preview {
    GoogleSignInButton()
        .environmentObject(AuthViewModel())
}
