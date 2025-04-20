//
//  Router.swift
//  GitHubDemo
//
//  Created by Aaron on 2025/4/20.
//

import SwiftUI
import Observation


enum AppDestination: Hashable {
    case login
    case userList
    case userDetail(username: String)
    case repositoryWebView(url: URL)
    case me
}


enum AppTab: Hashable {
    case userList
    case me
}


@Observable class AppRouter {

    static let shared = AppRouter()
    

    var selectedTab: AppTab = .userList
    

    var navigationPath = NavigationPath()
    

    var presentedSheet: AppDestination? = nil
    

    var presentedFullScreenCover: AppDestination? = nil
    
    private init() {}
    
    // MARK: - 导航方法

    func switchTab(to tab: AppTab) {
        selectedTab = tab
    }
    

    func navigate(to destination: AppDestination) {
        navigationPath.append(destination)
    }
    

    func navigateBack() {
        if !navigationPath.isEmpty {
            navigationPath.removeLast()
        }
    }
    

    func navigateToRoot() {
        navigationPath = NavigationPath()
    }
    

    func presentSheet(_ destination: AppDestination) {
        presentedSheet = destination
    }
    

    func dismissSheet() {
        presentedSheet = nil
    }
    
    
    func presentFullScreenCover(_ destination: AppDestination) {
        presentedFullScreenCover = destination
    }
    
    func dismissFullScreenCover() {
        presentedFullScreenCover = nil
    }
    
    // MARK: -
    
    func navigateToUserDetail(username: String) {
        navigate(to: .userDetail(username: username))
    }
    
    func openRepositoryWebView(url: URL) {
        presentSheet(.repositoryWebView(url: url))
    }
    
    func handleSuccessfulLogin() {
        navigateToRoot()
        switchTab(to: .userList)
    }
    
    func handleLogout() {
        navigateToRoot()
        presentFullScreenCover(.login)
    }
}

extension View {
    func withAppRouter() -> some View {
        self.environment(AppRouter.shared)
    }
}
