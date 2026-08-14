//
//  HelloClaudeApp.swift
//  HelloClaude
//
//  Created by 高橋正人 on 2026/08/12.
//

import SwiftUI

@main
struct HelloClaudeApp: App {
    init() {
        NotificationManager.shared.requestAuthorizationIfNeeded()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
