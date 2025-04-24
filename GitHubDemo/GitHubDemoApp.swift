//
//  GitHubDemoApp.swift
//  GitHubDemo
//
//  Created by Aaron on 2025/4/20.
//

import SwiftUI

@main
struct GitHubClientApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .withAppEnvironment() // 注入环境和所有服务
                .onOpenURL { url in
                    // 处理OAuth回调URL
                    if url.absoluteString.starts(with: AppEnvironment.shared.githubOAuthConfig.redirectURI) {
                        Task {
                            _ = await AppEnvironment.shared.authState.handleOAuthCallback(url: url)
                        }
                    }
                    
//                    // 将URL传递给LoginScreen处理
//                    NotificationCenter.default.post(name: .oauthCallbackReceived, object: url)
                }
        }
    }
}
