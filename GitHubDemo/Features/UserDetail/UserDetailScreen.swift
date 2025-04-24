//
//  UserDetailScreen.swift
//  GitHubDemo
//
//  Created by Aaron on 2025/4/24.
//

import SwiftUI

// UserDetailScreen视图模型


// 用户详情屏幕
struct UserDetailScreen: View {
    @Environment(AppRouter.self) private var router
    @State private var viewModel: UserDetailViewModel
    
    init(username: String) {
        _viewModel = State(initialValue: UserDetailViewModel(username: username))
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if viewModel.isLoading {
                    ProgressView("Loading user details...")
                        .padding()
                } else if let error = viewModel.error {
                    errorView(error)
                } else {
                    // 头像卡片
                    AvatarCard(url: viewModel.avatarUrl)
                        .frame(width: 150, height: 150)
                        .padding(.top, 20)
                    
                    // 用户信息卡片
                    userInfoCard
                    
                    // 仓库列表
                    repositoriesListView
                }
            }
            .padding(.horizontal)
        }
        .navigationTitle(viewModel.loginName)
        .onAppear {
            Task {
                await viewModel.loadUserData()
            }
        }
        .refreshable {
            await viewModel.loadUserData()
        }
    }
    
    // 用户信息卡片
    private var userInfoCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(viewModel.name)
                .font(.title)
            Text("@\(viewModel.loginName)")
                .font(.subheadline)
                .foregroundColor(.gray)
            
            HStack {
                VStack {
                    Text("\(viewModel.followers)")
                        .font(.headline)
                    Text("Followers")
                }
                Spacer()
                VStack {
                    Text("\(viewModel.following)")
                        .font(.headline)
                    Text("Following")
                }
            }.padding(.horizontal, 32)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(10)
        .shadow(radius: 2)
        .padding(.bottom)
    }
    
    // 仓库列表
    private var repositoriesListView: some View {
        VStack(alignment: .leading, spacing: 12) {
            if viewModel.unforkRepositories.isEmpty {
                Text("No repositories found")
                    .font(.headline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                Text("Repositories")
                    .font(.headline)
                    .padding(.leading, 4)
                
                ForEach(viewModel.unforkRepositories) { repo in
                    RepositoryRow(repository: repo) {
                        viewModel.openRepository(repo)
                    }
                }
            }
        }
    }
    
    // 错误视图
    private func errorView(_ error: Error) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 50))
                .foregroundColor(.orange)
            
            Text("Failed to load user details")
                .font(.headline)
            
            Text(error.localizedDescription)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button("Try Again") {
                Task {
                    await viewModel.loadUserData()
                }
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)
        }
        .padding()
        .frame(maxWidth: .infinity)
    }
}


// 预览
#Preview {
    NavigationView {
        UserDetailScreen(username: "octocat")
    }
    .environment(AppRouter.shared)
}
