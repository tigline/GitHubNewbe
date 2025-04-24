//
//  GithubAPI.swift
//  GitHubDemo
//
//  Created by Aaron on 2025/4/24.
//

import Foundation

@Observable class GitHubAPI {
    static let shared = GitHubAPI()
    
    private let apiClient: APIClient
    
    init(apiClient: APIClient = .shared) {
        self.apiClient = apiClient
    }
    
    // 设置认证Token
    func setToken(_ token: String) {
        apiClient.setToken(token)
    }
    
    // 清除认证Token
    func clearToken() {
        apiClient.clearToken()
    }
    
    // 获取用户列表
    func getUsers(since: Int = 0, perPage: Int = 30) async throws -> [User] {
        let queryItems = [
            URLQueryItem(name: "since", value: "\(since)"),
            URLQueryItem(name: "per_page", value: "\(perPage)")
        ]
        
        return try await apiClient.request(
            path: "/users",
            queryItems: queryItems
        )
    }
    
    // 获取用户详情
    func getUserDetail(username: String) async throws -> UserDetail {
        return try await apiClient.request(path: "/users/\(username)")
    }
    
    // 获取用户的仓库列表
    func getUserRepositories(username: String, page: Int = 1, perPage: Int = 30) async throws -> [Repository] {
        let queryItems = [
            URLQueryItem(name: "page", value: "\(page)"),
            URLQueryItem(name: "per_page", value: "\(perPage)"),
            URLQueryItem(name: "type", value: "owner") // 只获取用户自己的仓库，不包括fork
        ]
        
        return try await apiClient.request(
            path: "/users/\(username)/repos",
            queryItems: queryItems
        )
    }
    
    // 获取当前认证用户的信息
    func getCurrentUser() async throws -> UserDetail {
        return try await apiClient.request(path: "/user")
    }
    
    // 获取当前认证用户的仓库列表
    func getCurrentUserRepositories(page: Int = 1, perPage: Int = 30) async throws -> [Repository] {
        let queryItems = [
            URLQueryItem(name: "page", value: "\(page)"),
            URLQueryItem(name: "per_page", value: "\(perPage)"),
            URLQueryItem(name: "type", value: "owner") // 只获取用户自己的仓库，不包括fork
        ]
        
        return try await apiClient.request(
            path: "/user/repos",
            queryItems: queryItems
        )
    }
}
