//
//  UserListViewModel.swift
//  GitHubDemo
//
//  Created by Aaron on 2025/4/24.
//

import Observation
@Observable class UserListViewModel {
    // 数据
    var users: [User] = []
    var filteredUsers: [User] = []
    var searchText: String = ""
    
    // 状态
    var isLoading = false
    var error: Error?
    var currentPage = 0
    var hasMoreUsers = true
    
    // 依赖
    private let githubAPI: GitHubAPI
    private let router: AppRouter
    
    init(githubAPI: GitHubAPI = GitHubAPI.shared, router: AppRouter = AppRouter.shared) {
        self.githubAPI = githubAPI
        self.router = router
    }
    
    // 加载用户列表
    @MainActor
    func loadUsers(refresh: Bool = false) async {
        if refresh {
            currentPage = 0
            hasMoreUsers = true
        }
        
        guard hasMoreUsers && !isLoading else { return }
        
        isLoading = true
        error = nil
        
        do {
            let since = refresh ? 0 : (users.last?.id ?? 0)
            let newUsers = try await githubAPI.getUsers(since: since)
            
            if refresh {
                users = newUsers
            } else {
                users.append(contentsOf: newUsers)
            }
            
            hasMoreUsers = !newUsers.isEmpty
            currentPage += 1
            updateFilteredUsers()
        } catch {
            self.error = error
        }
        
        isLoading = false
    }
    
    // 根据搜索文本过滤用户
    func updateFilteredUsers() {
        if searchText.isEmpty {
            filteredUsers = users
        } else {
            filteredUsers = users.filter {
                $0.login.lowercased().contains(searchText.lowercased())
            }
        }
    }
    
    // 搜索文本变化处理
    func onSearchTextChanged(to newText: String) {
        searchText = newText
        updateFilteredUsers()
    }
    
    // 用户选择处理
    func userSelected(user: User) {
        router.navigateToUserDetail(username: user.login)
    }
    
    // 检查是否需要加载更多用户
    func shouldLoadMoreUsers(for user: User) -> Bool {
        // 如果用户是列表中的最后几个，并且还有更多用户可加载，则触发加载
        guard hasMoreUsers, !isLoading else { return false }
        let thresholdIndex = filteredUsers.count - 5
        return filteredUsers.firstIndex(where: { $0.id == user.id }) ?? 0 >= thresholdIndex
    }
}
