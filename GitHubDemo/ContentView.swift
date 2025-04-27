//
//  ContentView.swift
//  GitHubDemo
//
//  Created by Aaron on 2025/4/20.
//

import SwiftUI

struct ContentView: View {
    @Environment(AuthState.self) private var authState
    @Environment(AppRouter.self) private var router
    
    var body: some View {
        Group {
            if authState.isLoggedIn {
                TabView(selection: router.selectedTabBinding()) {
                    
                    UserListScreen()
                    .tabItem {
                        Label("Users", systemImage: "person.3")
                    }
                    .tag(AppTab.userList)
                    
                    MeScreen()
                    .tabItem {
                        Label("Me", systemImage: "person.circle")
                    }
                    .tag(AppTab.me)
                }
                
                .sheet(item: router.presentSheetBinding()) { destination in
                    switch destination {
                    case .repositoryWebView(let url):
                        SafariView(url: url) {
                            
                        }
                    default:
                        EmptyView()
                    }
                }
            } else {
                LoginScreen()
            }
        }
    }
}

#Preview {

    ContentView()
        .environment(AuthState.shared)
        .environment(AppRouter.shared)
    
}


