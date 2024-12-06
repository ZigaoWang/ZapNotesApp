//
//  AppearanceSettingsView.swift
//  Zap
//
//  Created by Zigao Wang on 9/27/24.
//

import SwiftUI

struct AppearanceSettingsView: View {
    @EnvironmentObject var appearanceManager: AppearanceManager
    
    var body: some View {
        Form {
            Section {
                ThemePickerView(selection: $appearanceManager.appTheme)
            } header: {
                SectionHeaderView(
                    title: "Theme",
                    icon: "sun.max.fill",
                    color: .orange
                )
            }
            
            Section {
                ColorPicker("Accent Color", selection: $appearanceManager.accentColor)
                    .onChange(of: appearanceManager.accentColor) { newValue in
                        appearanceManager.accentColorString = newValue.toHex() ?? "blue"
                    }
            } header: {
                SectionHeaderView(
                    title: "Accent Color",
                    icon: "paintpalette.fill",
                    color: appearanceManager.accentColor
                )
            }
        }
        .navigationTitle("Appearance")
    }
}

struct ThemePickerView: View {
    @Binding var selection: AppearanceManager.AppTheme
    
    var body: some View {
        Picker("App Theme", selection: $selection) {
            ForEach(AppearanceManager.AppTheme.allCases, id: \.self) { theme in
                HStack {
                    Image(systemName: themeIcon(for: theme))
                        .foregroundColor(themeColor(for: theme))
                    Text(theme.rawValue.capitalized)
                }
                .tag(theme)
            }
        }
        .pickerStyle(.menu)
    }
    
    private func themeIcon(for theme: AppearanceManager.AppTheme) -> String {
        switch theme {
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
        case .system: return "gear"
        }
    }
    
    private func themeColor(for theme: AppearanceManager.AppTheme) -> Color {
        switch theme {
        case .light: return .orange
        case .dark: return .purple
        case .system: return .gray
        }
    }
}

struct SectionHeaderView: View {
    let title: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(color)
            Text(title)
        }
        .textCase(nil)
        .font(.headline)
    }
}

// Preview
struct AppearanceSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            AppearanceSettingsView()
                .environmentObject(AppearanceManager())
        }
    }
}
