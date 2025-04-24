//
//  OAuthManager.swift
//  GitHubDemo
//
//  Created by Aaron on 2025/4/24.
//

import Foundation
import AuthenticationServices

enum OAuthError: Error {
    case invalidURL
    case authorizationFailed
    case tokenExchangeFailed
    case userCancelled
    case missingAuthorizationCode
    case networkError(Error)
}

@Observable class OAuthManager {
    static let shared = OAuthManager()
    
    // GitHub OAuth配置
    public var clientID = "YOUR_GITHUB_CLIENT_ID"
    public var clientSecret = "YOUR_GITHUB_CLIENT_SECRET"
    public var redirectURI = "http://127.0.0.1:PORT/callback"//"YOUR_APP_REDIRECT_URI"
    public var scope = "user repo"
    
    // 授权会话
    private var webAuthSession: ASWebAuthenticationSession?
    
    private init() {}
    
    // 启动OAuth流程
    func startOAuthFlow() {
        // 构建GitHub授权URL
        var components = URLComponents(string: "https://github.com/login/oauth/authorize")!
        components.queryItems = [
            URLQueryItem(name: "client_id", value: clientID),
            URLQueryItem(name: "redirect_uri", value: redirectURI),
            URLQueryItem(name: "scope", value: scope),
            URLQueryItem(name: "state", value: generateState())
        ]
        
        guard let authURL = components.url else {
            print("无法创建授权URL")
            return
        }
        
        // 使用ASWebAuthenticationSession进行OAuth认证
        webAuthSession = ASWebAuthenticationSession(
            url: authURL,
            callbackURLScheme: extractCallbackScheme(from: redirectURI),
            completionHandler: { [weak self] callbackURL, error in
                guard error == nil, let callbackURL = callbackURL else {
                    if let error = error as? ASWebAuthenticationSessionError {
                        if error.code == .canceledLogin {
                            print("用户取消了登录")
                        } else {
                            print("认证会话错误: \(error)")
                        }
                    }
                    return
                }
                
                // 处理回调URL
                Task {
                    do {
                        let token = try await self?.exchangeCodeForToken(from: callbackURL)
                        print("获取到访问令牌")
                        // 这里需要通知AuthState设置令牌
                        if let token = token {
                            AuthState().setAccessToken(token)
                        }
                    } catch {
                        print("获取访问令牌失败: \(error)")
                    }
                }
            }
        )
        
        // 设置会话的呈现上下文提供者
        webAuthSession?.presentationContextProvider = findPresentationContextProvider()
        webAuthSession?.prefersEphemeralWebBrowserSession = true
        
        // 启动认证会话
        webAuthSession?.start()
    }
    
    // 处理OAuth回调
    func handleCallback(url: URL) async throws -> String {
        // 从回调URL中提取授权码
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let code = components.queryItems?.first(where: { $0.name == "code" })?.value else {
            throw OAuthError.missingAuthorizationCode
        }
        
        // 交换授权码获取访问令牌
        return try await exchangeCodeForToken(code: code)
    }
    
    // 从回调URL中提取授权码并交换访问令牌
    private func exchangeCodeForToken(from url: URL) async throws -> String {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let code = components.queryItems?.first(where: { $0.name == "code" })?.value else {
            throw OAuthError.missingAuthorizationCode
        }
        
        return try await exchangeCodeForToken(code: code)
    }
    
    func exchangeCodeForToken(code: String) async throws -> String {
        var request = URLRequest(url: URL(string: "https://github.com/login/oauth/access_token")!)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let parameters: [String: Any] = [
            "client_id": clientID,
            "client_secret": clientSecret,
            "code": code,
            "redirect_uri": redirectURI
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: parameters)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // 检查响应状态
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw OAuthError.tokenExchangeFailed
        }
        
        // 解析JSON响应
        if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
           let accessToken = json["access_token"] as? String {
            return accessToken
        }
        
        throw OAuthError.tokenExchangeFailed
    }

    
    // 交换授权码获取访问令牌
    private func exchangeCodeForToken1(code: String) async throws -> String {
        // 构建令牌请求
        var components = URLComponents(string: "https://github.com/login/oauth/access_token")!
        components.queryItems = [
            URLQueryItem(name: "client_id", value: clientID),
            URLQueryItem(name: "client_secret", value: clientSecret),
            URLQueryItem(name: "code", value: code),
            URLQueryItem(name: "redirect_uri", value: redirectURI)
        ]
        
        guard let tokenURL = components.url else {
            throw OAuthError.invalidURL
        }
        
        var request = URLRequest(url: tokenURL)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        // 发送请求
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                throw OAuthError.tokenExchangeFailed
            }
            
            // 解析响应
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let accessToken = json["access_token"] as? String {
                return accessToken
            } else {
                // 尝试解析表单格式的响应
                if let responseString = String(data: data, encoding: .utf8),
                   let accessToken = extractAccessToken(from: responseString) {
                    return accessToken
                }
                throw OAuthError.tokenExchangeFailed
            }
        } catch {
            throw OAuthError.networkError(error)
        }
    }
    
    // 从表单格式的响应中提取访问令牌
    private func extractAccessToken(from response: String) -> String? {
        let components = response.components(separatedBy: "&")
        for component in components {
            let keyValue = component.components(separatedBy: "=")
            if keyValue.count == 2 && keyValue[0] == "access_token" {
                return keyValue[1]
            }
        }
        return nil
    }
    
    // 生成随机状态字符串，用于防止CSRF攻击
    private func generateState() -> String {
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<30).map { _ in letters.randomElement()! })
    }
    
    // 从重定向URI中提取回调方案
    private func extractCallbackScheme(from redirectURI: String) -> String? {
        guard let url = URL(string: redirectURI),
              let scheme = url.scheme else {
            return nil
        }
        return scheme
    }
    
    // 查找呈现上下文提供者
    private func findPresentationContextProvider() -> ASWebAuthenticationPresentationContextProviding {
        // 在实际应用中，这应该返回当前的视图控制器或窗口
        // 这里为简化示例，使用一个简单的实现
        return SimplePresentationContextProvider()
    }
}

// 简单的呈现上下文提供者实现
class SimplePresentationContextProvider: NSObject, ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        // 在实际应用中，这应该返回当前的窗口
        // 这里为简化示例，使用UIApplication的主窗口
        return UIApplication.shared.windows.first ?? ASPresentationAnchor()
    }
}
