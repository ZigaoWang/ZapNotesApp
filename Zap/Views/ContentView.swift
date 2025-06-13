//
//  ContentView.swift
//  Zap
//
//  Created by Zigao Wang on 9/18/24.
//

import SwiftUI

struct ContentView: View {
    @StateObject var viewModel = NotesViewModel()
    @EnvironmentObject var appearanceManager: AppearanceManager
    @State private var isOnboarding: Bool = !UserDefaults.standard.bool(forKey: "hasSeenOnboarding")

    var body: some View {
        if isOnboarding {
            OnboardingView(isOnboarding: $isOnboarding)
                .environmentObject(viewModel)
        } else {
            HomeView()
                .environmentObject(viewModel)
                .preferredColorScheme(appearanceManager.colorScheme)
                .accentColor(appearanceManager.accentColor)
                .onAppear {
                    // Ensure accent color is set correctly
                    if let color = Color(hex: appearanceManager.accentColorString) {
                        appearanceManager.setAccentColor(color)
                    }
                }
        }
    }
}
