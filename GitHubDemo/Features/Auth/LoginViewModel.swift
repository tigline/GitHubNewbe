//
//  LoginViewModel.swift
//  GitHubDemo
//
//  Created by Aaron on 2025/4/24.
//

import SwiftUI
import AuthenticationServices

// LoginScreen视图模型
@Observable class LoginScreenViewModel {
    // 状态
    var isLoading = false
    var errorMessage: String? = nil
    
    // 依赖
    private let authState: AuthState
    private let router: AppRouter
    private let environment: AppEnvironment
    
    // Web认证会话
    private var webAuthSession: ASWebAuthenticationSession?
    
    init(authState: AuthState, router: AppRouter, environment: AppEnvironment) {
        self.authState = authState
        self.router = router
        self.environment = environment
    }
    
    // 开始登录流程
    func startLogin() {
        isLoading = true
        errorMessage = nil
        
        // 构建GitHub授权URL
        let oauthConfig = environment.githubOAuthConfig
        let state = generateRandomState()
        
        var components = URLComponents(string: "https://github.com/login/oauth/authorize")!
        components.queryItems = [
            URLQueryItem(name: "client_id", value: oauthConfig.clientID),
            URLQueryItem(name: "redirect_uri", value: oauthConfig.redirectURI),
            URLQueryItem(name: "scope", value: oauthConfig.scope),
            URLQueryItem(name: "state", value: state)
        ]
        
        guard let authURL = components.url else {
            errorMessage = "Failed to create authorization URL"
            isLoading = false
            return
        }
        
        // 保存state用于后续验证
        UserDefaults.standard.set(state, forKey: "oauth_state")
        
        // 创建并启动Web认证会话
        webAuthSession = ASWebAuthenticationSession(
            url: authURL,
            callbackURLScheme: URL(string: oauthConfig.redirectURI)?.scheme,
            completionHandler: { [weak self] callbackURL, error in
                DispatchQueue.main.async {
                    self?.isLoading = false
                    
                    if let error = error {
                        if let authError = error as? ASWebAuthenticationSessionError,
                           authError.code == .canceledLogin {
                            // 用户取消了登录，不显示错误
                            self?.errorMessage = nil
                        } else {
                            self?.errorMessage = "Authentication failed: \(error.localizedDescription)"
                        }
                        return
                    }
                    
                    if let callbackURL = callbackURL {
                        self?.handleOAuthCallback(url: callbackURL)
                    }
                }
            }
        )
        
        // 设置呈现上下文
        webAuthSession?.presentationContextProvider = AuthenticationPresentationContextProvider.shared
        webAuthSession?.prefersEphemeralWebBrowserSession = true
        
        // 启动认证会话
        if webAuthSession?.start() != true {
            isLoading = false
            errorMessage = "Failed to start authentication session"
        }
    }
    
    // 处理OAuth回调
    func handleOAuthCallback(url: URL) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let queryItems = components.queryItems else {
            errorMessage = "Invalid callback URL"
            isLoading = false
            return
        }
        
        // 检查错误
        if let errorDescription = queryItems.first(where: { $0.name == "error_description" })?.value {
            errorMessage = "GitHub Error: \(errorDescription)"
            isLoading = false
            return
        }
        
        // 获取授权码和state
        guard let code = queryItems.first(where: { $0.name == "code" })?.value,
              let returnedState = queryItems.first(where: { $0.name == "state" })?.value,
              let savedState = UserDefaults.standard.string(forKey: "oauth_state"),
              returnedState == savedState else {
            errorMessage = "Invalid authorization response"
            isLoading = false
            return
        }
        
        // 清除保存的state
        UserDefaults.standard.removeObject(forKey: "oauth_state")
        
        // 交换授权码获取访问令牌
        exchangeCodeForToken(code: code)
    }
    
    // 交换授权码获取访问令牌
    private func exchangeCodeForToken(code: String) {
        isLoading = true
        
        let oauthConfig = environment.githubOAuthConfig
        
        var components = URLComponents(string: "https://github.com/login/oauth/access_token")!
        components.queryItems = [
            URLQueryItem(name: "client_id", value: oauthConfig.clientID),
            URLQueryItem(name: "client_secret", value: oauthConfig.clientSecret),
            URLQueryItem(name: "code", value: code),
            URLQueryItem(name: "redirect_uri", value: oauthConfig.redirectURI)
        ]
        
        guard let tokenURL = components.url else {
            errorMessage = "Failed to create token URL"
            isLoading = false
            return
        }
        
        var request = URLRequest(url: tokenURL)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    self?.errorMessage = "Network error: \(error.localizedDescription)"
                    return
                }
                
                guard let data = data else {
                    self?.errorMessage = "No data received"
                    return
                }
                
                // 尝试解析JSON响应
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let accessToken = json["access_token"] as? String {
                    // 成功获取访问令牌
                    self?.handleSuccessfulLogin(accessToken: accessToken)
                    return
                }
                
                // 尝试解析表单格式响应
                if let responseString = String(data: data, encoding: .utf8) {
                    let components = responseString.components(separatedBy: "&")
                    for component in components {
                        let keyValue = component.components(separatedBy: "=")
                        if keyValue.count == 2 && keyValue[0] == "access_token" {
                            // 成功获取访问令牌
                            self?.handleSuccessfulLogin(accessToken: keyValue[1])
                            return
                        }
                    }
                }
                
                self?.errorMessage = "Failed to parse token response"
            }
        }
        
        task.resume()
    }
    
    // 处理成功登录
    private func handleSuccessfulLogin(accessToken: String) {
        // 设置访问令牌
        authState.setAccessToken(accessToken)
        
        // 导航到主界面
        router.handleSuccessfulLogin()
    }
    
    // 不登录继续
    func continueWithoutLogin() {
        // 清除任何可能存在的令牌
        authState.logout()
        
        // 导航到主界面
        router.handleSuccessfulLogin()
    }
    
    // 生成随机state字符串
    private func generateRandomState() -> String {
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<30).map { _ in letters.randomElement()! })
    }
}

// 认证呈现上下文提供者
// 认证呈现上下文提供者
class AuthenticationPresentationContextProvider: NSObject, ASWebAuthenticationPresentationContextProviding {
    static let shared = AuthenticationPresentationContextProvider()
    
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        // 获取当前窗口作为呈现锚点（iOS 15+兼容方式）
        if let windowScene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene,
           let window = windowScene.windows.first {
            return window
        }
        
        // 备用方案，创建新窗口
        return UIWindow()
    }
}


