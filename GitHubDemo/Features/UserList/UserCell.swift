//
//  UserCell.swift
//  GitHubDemo
//
//  Created by Aaron on 2025/4/24.
//
import SwiftUI

struct UserCell: View {
    let user: User
    
    var body: some View {
        VStack {
            HStack {
                // avatar
                AsyncImage(url: URL(string: user.avatarUrl)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 60, height: 60)
                        .clipShape(Circle())
                } placeholder: {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 60, height: 60)
                        .foregroundColor(.gray)
                        .clipShape(Circle())
                }
                
                // name
                Text(user.login)
                    .font(.title2)
                    .padding(.leading, 8)
                    .foregroundColor(Color(UIColor.label))
                
                Spacer()
            }
            .padding(.all, 10)
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(10)
            .shadow(radius: 2)
        }
        .padding(.horizontal, 16)
    }
}
