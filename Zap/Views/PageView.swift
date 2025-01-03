//
//  PageView.swift
//  Zap
//
//  Created by Zigao Wang on 11/6/24.
//

import SwiftUI

struct PageView: View {
    var pages: [OnboardingPage]
    @Binding var currentPage: Int

    var body: some View {
        TabView(selection: $currentPage) {
            ForEach(0..<pages.count) { index in
                VStack {
                    Image(systemName: pages[index].iconName)
                        .resizable()
                        .scaledToFit()
                        .frame(height: IconSize.extraLarge)
                        .padding()

                    Text(pages[index].title)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding(.top)

                    Text(pages[index].description)
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .padding()
                }
                .tag(index)
            }
        }
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
    }
}
