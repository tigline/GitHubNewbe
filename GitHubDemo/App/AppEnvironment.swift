//
//  AppEnvironment.swift
//  GitHubDemo
//
//  Created by Aaron on 2025/4/24.
//

import Foundation
import SwiftUI

// 定义环境类型
enum EnvironmentType {
    case development
    case staging
    case production
    
    var description: String {
        switch self {
        case .development: return "Development"
        case .staging: return "Staging"
        case .production: return "Production"
        }
    }
}

// 应用环境配置类
@Observable class AppEnvironment {
    // 单例实例
    static let shared = AppEnvironment()
    
    // 当前环境类型
    let environmentType: EnvironmentType
    
    // GitHub API配置
    let githubAPIBaseURL: URL
    let githubOAuthConfig: GitHubOAuthConfig
    
    // 共享服务实例
    let apiClient: APIClient
    let githubAPI: GitHubAPI
    let authState: AuthState
    let router: AppRouter
    
    // 私有初始化方法，防止外部创建实例
    private init() {
        // 根据编译配置确定环境类型
        #if DEBUG
        self.environmentType = .development
        #elseif STAGING
        self.environmentType = .staging
        #else
        self.environmentType = .production
        #endif
        
        // 设置GitHub API基础URL
        self.githubAPIBaseURL = URL(string: "https://api.github.com")!
        
        // 设置GitHub OAuth配置
        self.githubOAuthConfig = GitHubOAuthConfig(
            clientID: "Iv23li0U7lAkQCBxtNId", // 替换为实际的GitHub客户端ID
            clientSecret: "61f83af0547fe1bead49bfe20c5dbb178adf4039", // 替换为实际的GitHub客户端密钥
            redirectURI: "githubclient://oauth-callback", // 替换为实际的重定向URI
            scope: "user repo"
        )
        
        // 初始化API客户端
        self.apiClient = APIClient(baseURL: githubAPIBaseURL)
        
        // 初始化GitHub API服务
        self.githubAPI = GitHubAPI(apiClient: apiClient)
        
        // 初始化认证状态
        self.authState = AuthState()
        
        // 初始化路由器
        self.router = AppRouter.shared
        
        // 设置依赖关系
        setupDependencies()
    }
    
    // 设置依赖关系
    private func setupDependencies() {
        // 将OAuth配置注入到OAuthManager
        OAuthManager.shared.configure(with: githubOAuthConfig)
    }
    
    // 重置环境（用于测试或登出）
    func reset() {
        authState.logout()
        apiClient.clearToken()
    }
}

// GitHub OAuth配置
struct GitHubOAuthConfig {
    let clientID: String
    let clientSecret: String
    let redirectURI: String
    let scope: String
}

// 为OAuthManager添加配置方法
extension OAuthManager {
    func configure(with config: GitHubOAuthConfig) {
        self.clientID = config.clientID
        self.clientSecret = config.clientSecret
        self.redirectURI = config.redirectURI
        self.scope = config.scope
    }
}

// 为了在SwiftUI中方便使用
struct AppEnvironmentKey: EnvironmentKey {
    static let defaultValue = AppEnvironment.shared
}

extension EnvironmentValues {
    var appEnvironment: AppEnvironment {
        get { self[AppEnvironmentKey.self] }
        set { self[AppEnvironmentKey.self] = newValue }
    }
}

// 便捷扩展，用于在视图中访问环境服务
extension View {
    func withAppEnvironment() -> some View {
        self.environment(\.appEnvironment, AppEnvironment.shared)
            .environment(AppRouter.shared)
            .environment(AppEnvironment.shared.authState)
    }
}

