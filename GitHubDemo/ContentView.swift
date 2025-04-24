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
                    NavigationStack(path: router.navigationPathBinding()) {
                        UserListScreen()
                            .navigationDestination(for: AppDestination.self) { destination in
                                switch destination {
                                case .userDetail(let username):
                                    UserDetailScreen(username: username)
                                default:
                                    EmptyView()
                                }
                            }
                    }
                    .tabItem {
                        Label("Users", systemImage: "person.3")
                    }
                    .tag(AppTab.userList)
                    
                    // 我的Tab
                    NavigationStack(path: router.navigationPathBinding()) {
                        MeScreen()
                    }
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
                .fullScreenCover(item: router.presentedFullScreenCoverBinding()) { destination in
                    switch destination {
                    case .login:
                        LoginScreen()
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




//// WebView页面实现
//struct WebViewScreen: View {
//    let url: URL
//    @Environment(AppRouter.self) private var router
//    
//    var body: some View {
//        NavigationStack {
//            WebView(url: url)
//                .navigationTitle("Repository")
//                .navigationBarTitleDisplayMode(.inline)
//                .toolbar {
//                    ToolbarItem(placement: .navigationBarTrailing) {
//                        Button("Done") {
//                            router.dismissSheet()
//                        }
//                    }
//                }
//        }
//    }
//}
//
//// WebView实现
//struct WebView: UIViewRepresentable {
//    let url: URL
//    
//    func makeUIView(context: Context) -> WKWebView {
//        let webView = WKWebView()
//        webView.navigationDelegate = context.coordinator
//        return webView
//    }
//    
//    func updateUIView(_ webView: WKWebView, context: Context) {
//        let request = URLRequest(url: url)
//        webView.load(request)
//    }
//    
//    func makeCoordinator() -> Coordinator {
//        Coordinator()
//    }
//    
//    class Coordinator: NSObject, WKNavigationDelegate {
//        // 可以在这里处理WebView导航事件
//    }
//}

