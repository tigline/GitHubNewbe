//
//  MeViewModel.swift
//  GitHubDemo
//
//  Created by Aaron on 2025/4/24.
//

import SwiftUI

// MeScreen视图模型
@Observable class MeViewModel {
    // 用户信息
    var userDetail: UserDetail?
    var repositories: [Repository] = []
    
    // 状态
    var isLoading = false
    var error: Error?
    
    // 依赖
    private let authState: AuthState
    private let router: AppRouter
    private let githubAPI: GitHubAPI
    
    // 计算属性 - 用于UI显示
    var userName: String {
        userDetail?.login ?? "User"
    }
    
    var name: String {
        userDetail?.name ?? userName
    }
    
    var email: String {
        userDetail?.email ?? "Not provided"
    }
    
    var location: String {
        userDetail?.location ?? "Not provided"
    }
    
    var followers: Int {
        userDetail?.followers ?? 0
    }
    
    var following: Int {
        userDetail?.following ?? 0
    }
    
    var avatar: URL? {
        if let avatarUrlString = userDetail?.avatarUrl {
            return URL(string: avatarUrlString)
        }
        return nil
    }
    
    var createdAt: Date {
        if let createdAtString = userDetail?.createdAt,
           let date = ISO8601DateFormatter().date(from: createdAtString) {
            return date
        }
        return Date()
    }
    
    init(authState: AuthState, router: AppRouter, githubAPI: GitHubAPI = GitHubAPI.shared) {
        self.authState = authState
        self.router = router
        self.githubAPI = githubAPI
    }
    
    // 加载用户数据
    @MainActor
    func loadUserData() async {
        // 如果未登录，则返回
        guard authState.isLoggedIn else {
            error = NSError(domain: "MeViewModel", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not logged in"])
            return
        }
        
        isLoading = true
        error = nil
        
        do {
            // 并行获取用户信息和仓库
            async let userDetailTask = githubAPI.getCurrentUser()
            async let repositoriesTask = githubAPI.getCurrentUserRepositories()
            
            let (userDetail, repositories) = try await (userDetailTask, repositoriesTask)
            
            self.userDetail = userDetail
            self.repositories = repositories.filter { !$0.fork } // 过滤掉fork的仓库
        } catch {
            self.error = error
        }
        
        isLoading = false
    }
    
    // 登出
    func logout() {
        authState.logout()
        router.handleLogout()
    }
}

