//
//  Repository.swift
//  GitHubDemo
//
//  Created by Aaron on 2025/4/24.
//

import Foundation

struct Repository: Identifiable, Decodable, Hashable {
    let id: Int
    let nodeId: String
    let name: String
    let fullName: String
    let owner: User
    let `private`: Bool
    let htmlUrl: URL
    let description: String?
    let fork: Bool
    let url: URL
    let createdAt: String
    let updatedAt: String
    let pushedAt: String
    let homepage: String?
    let size: Int
    let stargazersCount: Int
    let watchersCount: Int
    let language: String?
    let forksCount: Int
    let openIssuesCount: Int
    let defaultBranch: String
    let topics: [String]?
    let hasIssues: Bool
    let hasProjects: Bool
    let hasWiki: Bool
    let hasPages: Bool
    let hasDownloads: Bool
    let archived: Bool
    let disabled: Bool
    let visibility: String
    let license: License?
    
    struct License: Decodable, Hashable {
        let key: String
        let name: String
        let url: String?
        let spdxId: String?
        let nodeId: String
    }
}

// 为了支持UI展示的扩展
extension Repository {
    // 获取语言显示文本，无语言时返回"No Language"
    var languageDisplay: String {
        return language ?? "No Language"
    }
    
    // 获取格式化的星标数
    var stargazersCountDisplay: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: stargazersCount)) ?? "\(stargazersCount)"
    }
    
    // 获取简短描述，过长时截断
    var shortDescription: String {
        guard let desc = description, desc.count > 100 else {
            return description ?? "No description"
        }
        return String(desc.prefix(100)) + "..."
    }
}
