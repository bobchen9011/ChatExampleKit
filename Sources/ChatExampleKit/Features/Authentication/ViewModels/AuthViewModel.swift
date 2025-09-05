import Foundation
import Firebase
import FirebaseAuth
import GoogleSignIn
import FirebaseFirestore
#if canImport(UIKit)
import UIKit
#endif

internal class AuthViewModel: ObservableObject {
    @Published var currentUser: User? = nil
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var errorMessage = ""
    
    private let db = Firestore.firestore()
    
    init() {
        // 檢查當前用戶狀態
        checkAuthenticationState()
    }
    
    private func checkAuthenticationState() {
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            DispatchQueue.main.async {
                if let user = user {
                    self?.fetchUserData(for: user.uid)
                } else {
                    self?.currentUser = nil
                    self?.isAuthenticated = false
                }
            }
        }
    }
    
    // MARK: - Google Sign In
    func signInWithGoogle() {
        isLoading = true
        errorMessage = ""
        
#if canImport(UIKit)
        guard let presentingViewController = UIApplication.shared.windows.first?.rootViewController else {
            self.errorMessage = "無法找到根視圖控制器"
            self.isLoading = false
            return
        }
        
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            self.errorMessage = "Firebase 配置錯誤"
            self.isLoading = false
            return
        }
        
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config
        
        GIDSignIn.sharedInstance.signIn(withPresenting: presentingViewController) { [weak self] result, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    self?.errorMessage = "Google 登入失敗: \(error.localizedDescription)"
                    return
                }
                
                guard let user = result?.user,
                      let idToken = user.idToken?.tokenString else {
                    self?.errorMessage = "獲取用戶信息失敗"
                    return
                }
                
                let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: user.accessToken.tokenString)
                
                Auth.auth().signIn(with: credential) { authResult, error in
                    if let error = error {
                        self?.errorMessage = "Firebase 認證失敗: \(error.localizedDescription)"
                        return
                    }
                    
                    guard let firebaseUser = authResult?.user else {
                        self?.errorMessage = "無法獲取 Firebase 用戶"
                        return
                    }
                    
                    self?.createUserIfNeeded(firebaseUser: firebaseUser)
                }
            }
        }
#else
        self.errorMessage = "UIKit 不可用，無法執行 Google 登入"
        self.isLoading = false
#endif
    }
    
    // MARK: - Create User in Firestore
    private func createUserIfNeeded(firebaseUser: FirebaseAuth.User) {
        let userRef = db.collection("users").document(firebaseUser.uid)
        
        userRef.getDocument { [weak self] document, error in
            if let error = error {
                print("檢查用戶存在時發生錯誤: \(error)")
                return
            }
            
            if document?.exists == true {
                // 用戶已存在，直接獲取數據
                self?.fetchUserData(for: firebaseUser.uid)
            } else {
                // 創建新用戶
                let newUser = User(
                    id: firebaseUser.uid,
                    username: firebaseUser.displayName ?? "匿名用戶",
                    email: firebaseUser.email ?? "",
                    profileImageUrl: firebaseUser.photoURL?.absoluteString
                )
                
                do {
                    try userRef.setData(from: newUser) { error in
                        if let error = error {
                            print("創建用戶失敗: \(error)")
                        } else {
                            print("用戶創建成功")
                            self?.fetchUserData(for: firebaseUser.uid)
                        }
                    }
                } catch {
                    print("編碼用戶數據失敗: \(error)")
                }
            }
        }
    }
    
    // MARK: - Fetch User Data
    private func fetchUserData(for userId: String) {
        db.collection("users").document(userId).getDocument { [weak self] document, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("獲取用戶數據失敗: \(error)")
                    return
                }
                
                if let user = try? document?.data(as: User.self) {
                    self?.currentUser = user
                    self?.isAuthenticated = true
                    print("用戶數據獲取成功: \(user.username)")
                }
            }
        }
    }
    
    // MARK: - Sign Out
    func signOut() {
        do {
            try Auth.auth().signOut()
            GIDSignIn.sharedInstance.signOut()
            
            DispatchQueue.main.async {
                self.currentUser = nil
                self.isAuthenticated = false
                print("用戶登出成功")
            }
        } catch {
            print("登出失敗: \(error)")
        }
    }
    
    // MARK: - Delete Account
    func deleteAccount(completion: @escaping (Bool, String?) -> Void) {
        guard let user = Auth.auth().currentUser,
              let userId = currentUser?.id else {
            completion(false, "無法找到當前用戶")
            return
        }
        
        isLoading = true
        
        // 1. 先刪除 Firestore 中的用戶數據
        db.collection("users").document(userId).delete { [weak self] error in
            if let error = error {
                DispatchQueue.main.async {
                    self?.isLoading = false
                    completion(false, "刪除用戶數據失敗: \(error.localizedDescription)")
                }
                return
            }
            
            // 2. 刪除 Firebase Auth 用戶
            user.delete { error in
                DispatchQueue.main.async {
                    self?.isLoading = false
                    
                    if let error = error {
                        completion(false, "刪除帳號失敗: \(error.localizedDescription)")
                    } else {
                        // 3. 登出 Google
                        GIDSignIn.sharedInstance.signOut()
                        
                        // 4. 清除本地狀態
                        self?.currentUser = nil
                        self?.isAuthenticated = false
                        
                        completion(true, nil)
                        print("帳號刪除成功")
                    }
                }
            }
        }
    }
}