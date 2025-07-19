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
    
    private let githubURL = "https://github.com/ZapNotesApp/ZapNotesApp"
    private let licenseURL = "https://github.com/ZapNotesApp/ZapNotesApp/blob/main/LICENSE"

    let pages: [OnboardingPage] = {
        let preferredLanguages = Bundle.main.preferredLocalizations
        let isChineseLanguage = preferredLanguages.first?.hasPrefix("zh") ?? false
        
        if isChineseLanguage {
            return [
                OnboardingPage(title: "欢迎使用 Zap", description: "AI 驱动的笔记应用程序，用于记录和分析想法、创意和任务", useAppIcon: true),
                OnboardingPage(title: "多模态输入", description: "", iconSystemName: "square.grid.2x2", hasMultiModalInput: true),
                OnboardingPage(title: "开源免费", description: "无需订阅\n无广告", iconSystemName: "star.circle")
            ]
        } else {
            return [
                OnboardingPage(title: "Welcome to Zap", description: "AI-powered note-taking application for recording and analyzing thoughts, ideas, and tasks", useAppIcon: true),
                OnboardingPage(title: "Multi-Model Input", description: "", iconSystemName: "square.grid.2x2", hasMultiModalInput: true),
                OnboardingPage(title: "Open Source & Free", description: "No Subscriptions\nNo Ads", iconSystemName: "star.circle")
            ]
        }
    }()

    var body: some View {
        GeometryReader { geometry in
            VStack {
                Spacer()
                
                // Content
                VStack(spacing: 30) {
                    // Icon
                    Group {
                        if pages[currentPage].useAppIcon {
                            Image("ZapLogo")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 100, height: 100)
                                .cornerRadius(22)
                        } else {
                            Image(systemName: pages[currentPage].iconSystemName ?? "")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 60, height: 60)
                                .foregroundColor(.blue)
                        }
                    }
                    .padding(.bottom, 20)
                    
                    // Title and Description
                    Text(pages[currentPage].title)
                        .font(.system(size: 28, weight: .bold))
                        .multilineTextAlignment(.center)
                    
                    if !pages[currentPage].description.isEmpty {
                        Text(pages[currentPage].description)
                            .font(.body)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                            .foregroundColor(.secondary)
                    }
                    
                    // Multi-modal Input UI
                    if pages[currentPage].hasMultiModalInput {
                        HStack(spacing: 20) {
                            ForEach(["Text", "Photos", "Voice"], id: \.self) { type in
                                VStack {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 16)
                                            .fill(type == "Text" ? Color.green.opacity(0.2) :
                                                  type == "Photos" ? Color.orange.opacity(0.2) :
                                                  Color.blue.opacity(0.2))
                                            .frame(width: 80, height: 80)
                                        
                                        Image(systemName: type == "Text" ? "text.alignleft" :
                                                          type == "Photos" ? "photo" :
                                                          "mic.fill")
                                            .foregroundColor(type == "Text" ? .green :
                                                            type == "Photos" ? .orange :
                                                            .blue)
                                            .font(.system(size: 30))
                                    }
                                    Text(type)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .padding(.top, 20)
                    }
                }
                .frame(height: geometry.size.height * 0.6)
                
                Spacer()
                
                // Bottom Section
                VStack(spacing: 20) {
                    // Page Indicators
                    HStack(spacing: 8) {
                        ForEach(0..<pages.count, id: \.self) { index in
                            Circle()
                                .fill(index == currentPage ? Color.blue : Color.gray.opacity(0.3))
                                .frame(width: 8, height: 8)
                        }
                    }
                    
                    // Navigation Button
                    if currentPage == pages.count - 1 {
                        Button(action: {
                            isOnboarding = false
                            UserDefaults.standard.set(true, forKey: "hasSeenOnboarding")
                        }) {
                            Text("Get Started")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(14)
                        }
                        .padding(.horizontal, 32)
                        
                        HStack(spacing: 20) {
                            Button("GitHub") {
                                if let url = URL(string: githubURL) {
                                    UIApplication.shared.open(url)
                                }
                            }
                            Text("•")
                                .foregroundColor(.secondary)
                            Button("License") {
                                if let url = URL(string: licenseURL) {
                                    UIApplication.shared.open(url)
                                }
                            }
                        }
                        .font(.subheadline)
                        .foregroundColor(.blue)
                    } else {
                        Button(action: {
                            // Guard to prevent index overflow with rapid taps on button
                            guard currentPage < pages.count - 1 else { return }
                            withAnimation {
                                currentPage += 1
                            }
                        }) {
                            Text("Next")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(14)
                        }
                        .padding(.horizontal, 32)
                    }
                }
                .padding(.bottom, 40)
            }
        }
    }
}

struct OnboardingPage {
    let title: String
    let description: String
    let iconSystemName: String?
    var hasMultiModalInput: Bool = false
    var useAppIcon: Bool = false
    
    init(title: String, description: String, iconSystemName: String? = nil, hasMultiModalInput: Bool = false, useAppIcon: Bool = false) {
        self.title = title
        self.description = description
        self.iconSystemName = iconSystemName
        self.hasMultiModalInput = hasMultiModalInput
        self.useAppIcon = useAppIcon
    }
}
