//
//  GitHubDemoApp.swift
//  GitHubDemo
//
//  Created by Aaron on 2025/4/20.
//

import SwiftUI

@main
struct GitHubDemoApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
