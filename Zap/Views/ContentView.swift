//
//  ContentView.swift
//  Zap
//
//  Created by Zigao Wang on 9/18/24.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var authManager = AuthManager.shared
    @StateObject private var appearanceManager = AppearanceManager()
    
    var body: some View {
        Group {
            if authManager.isAuthenticated {
                HomeView()
                    .environmentObject(authManager)
                    .environmentObject(appearanceManager)
            } else {
                LoginView()
                    .environmentObject(authManager)
            }
        }
        .environment(\.customFontSize, appearanceManager.fontSizeValue)
        .preferredColorScheme(appearanceManager.colorScheme)
        .accentColor(appearanceManager.accentColor)
    }
}
