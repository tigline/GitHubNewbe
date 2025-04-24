//
//  LoginScreen.swift
//  GitHubDemo
//
//  Created by Aaron on 2025/4/24.
//

import SwiftUI

// LoginScreen视图
struct LoginScreen: View {
    @Environment(AuthState.self) private var authState
    @Environment(AppRouter.self) private var router
    @Environment(\.appEnvironment) private var environment
    
    @State private var viewModel: LoginScreenViewModel
    
    init() {
        // 创建视图模型并注入依赖
        _viewModel = State(initialValue: LoginScreenViewModel(
            authState: AuthState.shared,
            router: AppRouter.shared,
            environment: AppEnvironment.shared
        ))
    }
    
    var body: some View {
        ZStack {
            // 背景
            Color(UIColor.systemBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 30) {
                // Logo和标题
                VStack(spacing: 16) {
                    Image(systemName: "person.3.fill")
                        .font(.system(size: 70))
                        .foregroundColor(.blue)
                    
                    Text("GitHub Client")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Sign in with your GitHub account to access repositories and user information.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                
                Spacer()
                
                // 登录按钮
                Button(action: { viewModel.startLogin() }) {
                    HStack {
                        Image(systemName: "person.circle.fill")
                            .font(.title3)
                        
                        Text("Sign in with GitHub")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .disabled(viewModel.isLoading)
                .padding(.horizontal, 32)
                
                // 无需登录继续按钮（使用有限的API调用）
                Button(action: { viewModel.continueWithoutLogin() }) {
                    Text("Continue without login (limited to 60 requests/hour)")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
                .padding(.bottom, 16)
                
                // 错误信息
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                
                // 加载指示器
                if viewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .scaleEffect(1.5)
                        .padding()
                }
                
                Spacer()
                
                // 环境信息（仅在开发环境显示）
                if environment.environmentType == .development {
                    Text("Environment: \(environment.environmentType.description)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
        }
        .onOpenURL { url in
            // 处理OAuth回调URL
            viewModel.handleOAuthCallback(url: url)
        }
        .onAppear {
            // 更新ViewModel的依赖
            viewModel = LoginScreenViewModel(
                authState: authState,
                router: router,
                environment: environment
            )
        }
    }
}

// 预览
#Preview {
    LoginScreen()
        .environment(AuthState.shared)
        .environment(AppRouter.shared)
        .environment(\.appEnvironment, AppEnvironment.shared)
}
