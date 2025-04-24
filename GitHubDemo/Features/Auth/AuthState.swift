//
//  AuthState.swift
//  GitHubDemo
//
//  Created by Aaron on 2025/4/24.
//

import Foundation
import SwiftUI

@Observable class AuthState {
    // 登录状态
    var isLoggedIn: Bool = false
    
    // 访问令牌
    private var accessToken: String?
    
    // 令牌过期时间
    private var tokenExpirationDate: Date?
    
    // 用户信息
    var currentUser: UserDetail?
    
    // KeyChain服务标识符
    private let keychainServiceID = "com.githubclient.auth"
    
    init() {
        loadTokenFromKeychain()
    }
    
    // 从钥匙串加载令牌
    private func loadTokenFromKeychain() {
        if let token = KeychainHelper.shared.read(service: keychainServiceID, account: "github_access_token") {
            self.accessToken = token
            self.isLoggedIn = true
            
            // 获取当前用户信息
            Task {
                await fetchCurrentUser()
            }
        }
    }
    
    // 保存令牌到钥匙串
    private func saveTokenToKeychain(token: String) {
        KeychainHelper.shared.save(token, service: keychainServiceID, account: "github_access_token")
    }
    
    // 从钥匙串删除令牌
    private func removeTokenFromKeychain() {
        KeychainHelper.shared.delete(service: keychainServiceID, account: "github_access_token")
    }
    
    // 设置访问令牌
    func setAccessToken(_ token: String) {
        self.accessToken = token
        self.isLoggedIn = true
        saveTokenToKeychain(token: token)
        
        // 设置API客户端的令牌
        GitHubAPI.shared.setToken(token)
        
        // 获取当前用户信息
        Task {
            await fetchCurrentUser()
        }
    }
    
    // 获取访问令牌
    func getAccessToken() -> String? {
        return accessToken
    }
    
    // 登出
    func logout() {
        self.accessToken = nil
        self.isLoggedIn = false
        self.currentUser = nil
        removeTokenFromKeychain()
        
        // 清除API客户端的令牌
        GitHubAPI.shared.clearToken()
    }
    
    // 获取当前用户信息
    @MainActor
    func fetchCurrentUser() async {
        guard isLoggedIn, accessToken != nil else { return }
        
        do {
            currentUser = try await GitHubAPI.shared.getCurrentUser()
        } catch {
            // 如果获取用户信息失败，可能是令牌无效
            if case APIError.unauthorized = error {
                logout()
            }
            print("获取用户信息失败: \(error)")
        }
    }
    
    // 启动GitHub OAuth流程
    func startOAuthFlow() {
        // 这里将实现OAuth流程的开始部分
        // 通常是构建授权URL并打开Safari进行认证
        // 具体实现将在OAuthManager中完成
        OAuthManager.shared.startOAuthFlow()
    }
    
    // 处理OAuth回调
    func handleOAuthCallback(url: URL) async -> Bool {
        // 处理OAuth回调，获取授权码并交换访问令牌
        do {
            let token = try await OAuthManager.shared.handleCallback(url: url)
            setAccessToken(token)
            return true
        } catch {
            print("OAuth认证失败: \(error)")
            return false
        }
    }
}

// 辅助类：钥匙串操作
class KeychainHelper {
    static let shared = KeychainHelper()
    private init() {}
    
    func save(_ data: String, service: String, account: String) {
        if let data = data.data(using: .utf8) {
            let query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: service,
                kSecAttrAccount as String: account,
                kSecValueData as String: data
            ]
            
            // 先删除可能存在的旧数据
            SecItemDelete(query as CFDictionary)
            
            // 保存新数据
            SecItemAdd(query as CFDictionary, nil)
        }
    }
    
    func read(service: String, account: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        if status == errSecSuccess, let data = result as? Data {
            return String(data: data, encoding: .utf8)
        }
        return nil
    }
    
    func delete(service: String, account: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        
        SecItemDelete(query as CFDictionary)
    }
}
