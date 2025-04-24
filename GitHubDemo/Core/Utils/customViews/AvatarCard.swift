//
//  AvatarCard.swift
//  GitHubDemo
//
//  Created by Aaron on 2025/4/24.
//

import SwiftUI

//struct AvatarCard: View {
//    let url: URL
//
//    var body: some View {
//        AsyncImage(url: url) { image in
//            image.resizable().scaledToFit()
//        } placeholder: {
//            ProgressView()
//        }
//        .clipShape(Circle())
//        .overlay(
//            Circle().stroke(Color.white, lineWidth: 4)
//        )
//        .shadow(radius: 7)
//        .padding()
//        .clipShape(RoundedRectangle(cornerRadius: 20))
//        .padding(.bottom)
//    }
//}

struct AvatarCard: View {
    let url: URL?
    
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.gray.opacity(0.2))
            
            if let url = url {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFit()
                    case .failure:
                        Image(systemName: "person.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                    @unknown default:
                        EmptyView()
                    }
                }
                .clipShape(Circle())
                .overlay(
                    Circle().stroke(Color.white, lineWidth: 4)
                )
                .shadow(radius: 7)
                .padding()
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .padding(.bottom)
            } else {
                Image(systemName: "person.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.gray)
            }
        }
    }
}
