//
//  Router.swift
//  GitHubDemo
//
//  Created by Aaron on 2025/4/20.
//

import SwiftUI
import Observation


enum AppDestination: Hashable, Identifiable {
    
    case userDetail(username: String)
    case repositoryWebView(url: URL)
    
    var id: Self { self }
}


enum AppTab: Hashable {
    case userList
    case me
}


@Observable class AppRouter {

    static let shared = AppRouter()
    

    var selectedTab: AppTab = .userList
    
    func selectedTabBinding() -> Binding<AppTab> {
        Binding(
            get: { self.selectedTab },
            set: { self.selectedTab = $0 }
        )
    }
    

    var navigationPath = NavigationPath()
    
    func navigationPathBinding() -> Binding<NavigationPath> {
       Binding(
           get: { self.navigationPath },
           set: { self.navigationPath = $0 }
       )
   }
    

    var presentedSheet: AppDestination? = nil
    
    func presentSheetBinding() -> Binding<AppDestination?> {
        Binding(
            get: { self.presentedSheet },
            set: { self.presentedSheet = $0 }
        )
    }
    

    var presentedFullScreenCover: AppDestination? = nil
    
    func presentedFullScreenCoverBinding() -> Binding<AppDestination?> {
        Binding(
            get: { self.presentedFullScreenCover},
            set: { self.presentedFullScreenCover = $0 }
        )
    }
    
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
    }
}

extension View {
    func withAppRouter() -> some View {
        self.environment(AppRouter.shared)
    }
}
