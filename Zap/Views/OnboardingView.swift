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

    let pages: [OnboardingPage] = {
        let preferredLanguages = Bundle.main.preferredLocalizations
        let isChineseLanguage = preferredLanguages.first?.hasPrefix("zh") ?? false
        
        if isChineseLanguage {
            return [
                OnboardingPage(title: "欢迎使用 Zap 笔记！", description: "Zap 是一款由 AI 驱动的笔记应用，帮助您轻松记录想法、创意和任务。", iconName: "note.text"),
                OnboardingPage(title: "多模态输入", description: "使用文本、语音和照片创建笔记。灵活选择最适合您的记录方式。", iconName: "mic.fill"),
                OnboardingPage(title: "智能总结", description: "使用 AI 获取笔记的简洁摘要，让您更轻松地回顾和管理想法。", iconName: "text.bubble"),
                OnboardingPage(title: "笔记整理", description: "轻松管理和分类您的笔记，实现快速访问和更好的组织。", iconName: "folder.fill"),
                OnboardingPage(title: "开源免费", description: "无需订阅，无广告。由王子高开发。", iconName: "star.fill")
            ]
        } else {
            return [
                OnboardingPage(title: "Welcome to Zap Notes!", description: "Zap is an AI-powered note-taking app that helps you capture your thoughts, ideas, and tasks effortlessly.", iconName: "note.text"),
                OnboardingPage(title: "Multi-modal Input", description: "Create notes using text, voice, and photos. Flexibility to capture your ideas in the way that suits you best.", iconName: "mic.fill"),
                OnboardingPage(title: "Smart Summarization", description: "Get concise summaries of your notes with AI, making it easier to review and manage your thoughts.", iconName: "text.bubble"),
                OnboardingPage(title: "Organize Your Notes", description: "Easily manage and categorize your notes for quick access and better organization.", iconName: "folder.fill"),
                OnboardingPage(title: "Open Source & Free", description: "No subscriptions, no ads. Made by Zigao Wang.", iconName: "star.fill")
            ]
        }
    }()

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

        // Place the "More Links" button above the page indicators
        if currentPage == pages.count - 1 && showButtons {
            Menu {
                Button("Zigao Wang's Profile") {
                    openURL("https://zigao.wang")
                }
                Button("GitHub Repository") {
                    openURL("https://github.com/ZapNotesApp/Zap")
                }
                Button("Official Website") {
                    openURL("https://zap-notes.com")
                }
            } label: {
                Text("More Links")
                    .font(.headline)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.bottom, 20) // Add some space between the button and the page indicators
        }

        PageControl(numberOfPages: pages.count, currentPage: $currentPage)
            .padding(.top, 20)

        if currentPage == pages.count - 1 {
            VStack(spacing: 20) {
                Button(action: {
                    isOnboarding = false
                    UserDefaults.standard.set(true, forKey: "hasSeenOnboarding")
                }) {
                    Text("Get Started")
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding(.top, 20)
                .transition(.opacity) // Add transition effect
            }
            .padding()
            .animation(.easeInOut, value: showButtons) // Animate the button appearance
        }
    }
    .padding()
}

private func openURL(_ urlString: String) {
    if let url = URL(string: urlString) {
        UIApplication.shared.open(url)
    }
}
}

struct OnboardingPage {
    let title: String
    let description: String
    let iconName: String
}
