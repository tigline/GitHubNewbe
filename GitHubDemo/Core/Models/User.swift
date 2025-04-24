//
//  User.swift
//  GitHubDemo
//
//  Created by Aaron on 2025/4/24.
//

struct User: Identifiable, Decodable, Hashable {
    let id: Int
    let login: String
    let nodeId: String
    let avatarUrl: String
    let gravatarId: String
    let url: String
    let htmlUrl: String
    let followersUrl: String
    let followingUrl: String
    let gistsUrl: String
    let starredUrl: String
    let subscriptionsUrl: String
    let organizationsUrl: String
    let reposUrl: String
    let eventsUrl: String
    let receivedEventsUrl: String
    let type: String
    let siteAdmin: Bool
}
