//
//  UserListScreen.swift
//  GitHubDemo
//
//  Created by Aaron on 2025/4/24.
//

import SwiftUI

// 用户列表屏幕
struct UserListScreen: View {
    @Environment(AppRouter.self) private var router
    @State private var viewModel = UserListViewModel()
    @State private var searchText = ""
    
    var body: some View {
        //NavigationStack(path: router.navigationPath) {
            ZStack {
                // 背景
                Color(UIColor.systemBackground)
                    .ignoresSafeArea()
                
                VStack {
                    // 搜索栏
                    searchBar
                    
                    // 用户列表
                    if viewModel.isLoading && viewModel.users.isEmpty {
                        // 初始加载
                        ProgressView("Loading users...")
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if let error = viewModel.error, viewModel.users.isEmpty {
                        // 错误状态（仅当列表为空时显示）
                        errorView(error)
                    } else {
                        // 用户列表
                        userListView
                    }
                }
            }
            .navigationTitle("GitHub Users")
//            .navigationDestination(for: AppDestination.self) { destination in
//                switch destination {
//                case .userDetail(let username):
//                    UserDetailScreen(username: username)
//                default:
//                    EmptyView()
//                }
//            }
            .onAppear {
                // 首次加载
                if viewModel.users.isEmpty {
                    Task {
                        await viewModel.loadUsers()
                    }
                }
            }
//        }
    }
    
    // 搜索栏
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            
            TextField("Search users", text: $searchText)
                .onChange(of: searchText) { oldValue, newValue in
                    viewModel.onSearchTextChanged(to: newValue)
                }
            
            if !searchText.isEmpty {
                Button(action: {
                    searchText = ""
                    viewModel.onSearchTextChanged(to: "")
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(10)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(10)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
    
    // 用户列表视图
    private var userListView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(viewModel.filteredUsers) { user in
                    Button {
                        viewModel.userSelected(user: user)
                    } label: {
                        UserCell(user: user)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .onAppear {
                        // 检查是否需要加载更多用户
                        if viewModel.shouldLoadMoreUsers(for: user) {
                            Task {
                                await viewModel.loadUsers()
                            }
                        }
                    }
                }
                
                // 底部加载指示器
                if viewModel.isLoading && !viewModel.users.isEmpty {
                    ProgressView()
                        .padding()
                }
            }
            .padding(.vertical, 8)
        }
        .refreshable {
            // 下拉刷新
            await viewModel.loadUsers(refresh: true)
        }
    }
    
    // 错误视图
    private func errorView(_ error: Error) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 50))
                .foregroundColor(.orange)
            
            Text("Failed to load users")
                .font(.headline)
            
            Text(error.localizedDescription)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button("Try Again") {
                Task {
                    await viewModel.loadUsers(refresh: true)
                }
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// 预览
#Preview {
    UserListScreen()
        .environment(AppRouter.shared)
}

