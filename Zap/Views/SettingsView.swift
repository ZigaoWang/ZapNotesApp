//
//  SettingsView.swift
//  Zap
//
//  Created by Zigao Wang on 9/27/24.
//

import SwiftUI

struct SettingsView: View {
    var body: some View {
        NavigationView {
            List {
                Section {
                    NavigationLink(destination: AppearanceSettingsView()) {
                        SettingsRowView(
                            title: "Appearance",
                            icon: "paintbrush.fill",
                            iconColor: .purple,
                            description: "Customize theme, colors and text size"
                        )
                    }
                    
                    NavigationLink(destination: AboutHelpView()) {
                        SettingsRowView(
                            title: "About & Help",
                            icon: "info.circle.fill",
                            iconColor: .blue,
                            description: "App information and support"
                        )
                    }
                }
                .listRowBackground(Color(.secondarySystemGroupedBackground))
            }
            .navigationTitle("Settings")
            .listStyle(InsetGroupedListStyle())
        }
    }
}

struct SettingsRowView: View {
    let title: String
    let icon: String
    let iconColor: Color
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundColor(iconColor)
                .frame(width: 32, height: 32)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
