//
//  MeScreen.swift
//  GitHubDemo
//
//  Created by Aaron on 2025/4/24.
//

import SwiftUI

struct MeScreen: View {
    @Environment(AuthState.self) private var authState
    @Environment(AppRouter.self) private var router
    
    @State private var viewModel: MeViewModel
    
    init() {
        // 创建视图模型并注入依赖
        _viewModel = State(initialValue: MeViewModel(
            authState: AuthState(),
            router: AppRouter.shared
        ))
    }
    
    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView("Loading profile...")
            } else if let error = viewModel.error {
                VStack {
                    Text("Error loading profile")
                        .font(.headline)
                        .foregroundColor(.red)
                    
                    Text(error.localizedDescription)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding()
                    
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
            } else {
                ScrollView {
                    VStack(spacing: 20) {
                        // 头像
                        AvatarCard(url: viewModel.avatar)
                            .frame(width: 150, height: 150)
                        
                        // 用户信息卡片
                        VStack(spacing: 10) {
                            Text(viewModel.name)
                                .font(.title)
                            
                            HStack {
                                Text("Email:")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                Spacer()
                                Text(viewModel.email)
                                    .font(.subheadline)
                            }
                            
                            HStack {
                                Text("Location:")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                Spacer()
                                Text(viewModel.location)
                                    .font(.subheadline)
                            }
                            
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
                            
                            Text("Joined on \(formattedDate(date: viewModel.createdAt))")
                                .font(.footnote)
                                .foregroundColor(.gray)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(10)
                        .shadow(radius: 2)
                        .padding(.bottom)
                        .padding(.horizontal, 16)
                        
                        // 仓库列表（如果需要）
                        if !viewModel.repositories.isEmpty {
                            VStack(alignment: .leading) {
                                Text("Repositories")
                                    .font(.headline)
                                    .padding(.horizontal, 16)
                                
                                ForEach(viewModel.repositories) { repo in
                                    RepositoryRow(repository: repo) {
                                        if let url = URL(string: repo.htmlUrl.absoluteString) {
                                            router.openRepositoryWebView(url: url)
                                        }
                                    }
                                    .padding(.horizontal, 16)
                                }
                            }
                        }
                        
                        Spacer()
                        
                        // 登出按钮
                        Button(action: {
                            viewModel.logout()
                        }) {
                            Text("Log Out")
                                .foregroundColor(.white)
                                .frame(width: 200, height: 50)
                                .background(Color.red)
                                .cornerRadius(10)
                        }
                        .padding(.bottom, 20)
                    }
                }
                .navigationTitle(viewModel.userName)
                .refreshable {
                    await viewModel.loadUserData()
                }
            }
        }
        .onAppear {
            // 更新ViewModel的依赖
            viewModel = MeViewModel(
                authState: authState,
                router: router
            )
            
            // 加载用户数据
            Task {
                await viewModel.loadUserData()
            }
        }
    }
    
    func formattedDate(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}


#Preview {
    NavigationView {
        MeScreen()
            .environment(AuthState())
            .environment(AppRouter.shared)
    }
}
