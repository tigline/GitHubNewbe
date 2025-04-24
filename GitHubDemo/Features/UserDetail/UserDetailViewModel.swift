//
//  UserDetailViewModel.swift
//  GitHubDemo
//
//  Created by Aaron on 2025/4/24.
//

import Observation
import Foundation

@Observable class UserDetailViewModel {
    // 数据
    var userDetail: UserDetail?
    var repositories: [Repository] = []
    var unforkRepositories: [Repository] = []
    
    // 状态
    var isLoading = false
    var error: Error?
    
    // 依赖
    private let githubAPI: GitHubAPI
    private let router: AppRouter
    private let username: String
    
    init(username: String, githubAPI: GitHubAPI = GitHubAPI.shared, router: AppRouter = AppRouter.shared) {
        self.username = username
        self.githubAPI = githubAPI
        self.router = router
    }
    
    // 加载用户详情和仓库
    @MainActor
    func loadUserData() async {
        isLoading = true
        error = nil
        
        do {
            // 并行获取用户详情和仓库列表
            async let userDetailTask = githubAPI.getUserDetail(username: username)
            async let repositoriesTask = githubAPI.getUserRepositories(username: username)
            
            let (userDetail, repositories) = try await (userDetailTask, repositoriesTask)
            
            self.userDetail = userDetail
            self.repositories = repositories
            
            // 过滤出非fork的仓库
            self.unforkRepositories = repositories.filter { !$0.fork }
        } catch {
            self.error = error
        }
        
        isLoading = false
    }
    
    // 打开仓库网页
    func openRepository(_ repository: Repository) {
        router.openRepositoryWebView(url: repository.htmlUrl)
    }
    
    // 计算属性 - 用于UI显示
    var name: String {
        userDetail?.name ?? username
    }
    
    var loginName: String {
        userDetail?.login ?? username
    }
    
    var followers: Int {
        userDetail?.followers ?? 0
    }
    
    var following: Int {
        userDetail?.following ?? 0
    }
    
    var avatarUrl: URL? {
        if let avatarUrlString = userDetail?.avatarUrl {
            return URL(string: avatarUrlString)
        }
        return nil
    }
}
