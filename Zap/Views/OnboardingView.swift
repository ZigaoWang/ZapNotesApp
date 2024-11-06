//
//  OnboardingView.swift
//  Zap
//
//  Created by Zigao Wang on 11/6/24.
//

import SwiftUI

struct OnboardingView: View {
    @Binding var isOnboarding: Bool
    @State private var currentPage = 0
    @State private var showButtons = false // State to control button visibility

    let pages: [OnboardingPage] = [
        OnboardingPage(title: "Welcome to Zap!", description: "Zap is an AI-powered note-taking app that helps you capture your thoughts, ideas, and tasks effortlessly.", iconName: "note.text"),
        OnboardingPage(title: "Multi-modal Input", description: "Create notes using text, voice, and photos. Flexibility to capture your ideas in the way that suits you best.", iconName: "mic.fill"),
        OnboardingPage(title: "Smart Summarization", description: "Get concise summaries of your notes with AI, making it easier to review and manage your thoughts.", iconName: "text.bubble"),
        OnboardingPage(title: "Organize Your Notes", description: "Easily manage and categorize your notes for quick access and better organization.", iconName: "folder.fill"),
        OnboardingPage(title: "Open Source & Free", description: "No subscriptions, no ads. Made by Zigao Wang.", iconName: "star.fill")
    ]

    var body: some View {
        VStack {
            PageView(pages: pages, currentPage: $currentPage)
                .onChange(of: currentPage) { newValue in
                    // Show buttons when reaching the last page
                    if newValue == pages.count - 1 {
                        withAnimation(.easeIn(duration: 0.5)) {
                            showButtons = true
                        }
                    } else {
                        showButtons = false
                    }
                }

            PageControl(numberOfPages: pages.count, currentPage: $currentPage)
                .padding(.top, 20)

            if currentPage == pages.count - 1 {
                VStack(spacing: 20) {
                    Text("Check out the links below:")
                        .font(.headline)
                        .padding()

                    // Fade-in effect for buttons
                    if showButtons {
                        Button(action: {
                            if let url = URL(string: "https://zigao.wang") {
                                UIApplication.shared.open(url)
                            }
                        }) {
                            Text("Zigao Wang's Profile")
                                .font(.headline)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }

                        Button(action: {
                            if let url = URL(string: "https://github.com/ZapNotesApp/Zap") {
                                UIApplication.shared.open(url)
                            }
                        }) {
                            Text("GitHub Repository")
                                .font(.headline)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }

                        Button(action: {
                            if let url = URL(string: "https://zap-notes.com") {
                                UIApplication.shared.open(url)
                            }
                        }) {
                            Text("Official Website")
                                .font(.headline)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }

                        Button(action: {
                            isOnboarding = false
                            UserDefaults.standard.set(true, forKey: "hasSeenOnboarding")
                        }) {
                            Text("Get Started")
                                .font(.headline)
                                .padding()
                                .background(Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                        .padding(.top, 20)
                        .transition(.opacity) // Add transition effect
                    }
                }
                .padding()
                .animation(.easeInOut, value: showButtons) // Animate the button appearance
            }
        }
        .padding()
    }
}

struct OnboardingPage {
    let title: String
    let description: String
    let iconName: String
}
