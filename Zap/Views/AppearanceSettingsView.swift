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
                    title: NSLocalizedString("Theme", comment: "Theme section header"),
                    icon: "sun.max.fill",
                    color: .orange
                )
            }
            
            Section {
                ColorPicker(NSLocalizedString("Accent Color", comment: "Accent color picker"), selection: $appearanceManager.accentColor)
                    .onChange(of: appearanceManager.accentColor) { newValue in
                        appearanceManager.accentColorString = newValue.toHex() ?? "blue"
                    }
            } header: {
                SectionHeaderView(
                    title: NSLocalizedString("Accent Color", comment: "Accent color section header"),
                    icon: "paintpalette.fill",
                    color: appearanceManager.accentColor
                )
            }
            
            Section {
                RecordingModePickerView(selection: $appearanceManager.recordingMode)
            } header: {
                SectionHeaderView(
                    title: NSLocalizedString("Recording Mode", comment: "Recording mode section header"),
                    icon: "mic.fill",
                    color: .blue
                )
            } footer: {
                Text(NSLocalizedString("Tap mode: Press once to start recording and again to stop. Hold mode: Press and hold to record, release to stop.", comment: "Recording mode explanation"))
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
        }
        .navigationTitle(NSLocalizedString("Appearance", comment: "Appearance settings title"))
    }
}

struct ThemePickerView: View {
    @Binding var selection: AppearanceManager.AppTheme
    
    var body: some View {
        Picker(NSLocalizedString("App Theme", comment: "App theme picker"), selection: $selection) {
            ForEach(AppearanceManager.AppTheme.allCases, id: \.self) { theme in
                HStack {
                    Image(systemName: themeIcon(for: theme))
                        .foregroundColor(themeColor(for: theme))
                    Text(themeLocalizedName(for: theme))
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
    
    private func themeLocalizedName(for theme: AppearanceManager.AppTheme) -> String {
        switch theme {
        case .light: return NSLocalizedString("Light", comment: "Light theme")
        case .dark: return NSLocalizedString("Dark", comment: "Dark theme")
        case .system: return NSLocalizedString("System", comment: "System theme")
        }
    }
}

struct RecordingModePickerView: View {
    @Binding var selection: AppearanceManager.RecordingMode
    
    var body: some View {
        Picker(NSLocalizedString("Recording Mode", comment: "Recording mode picker"), selection: $selection) {
            ForEach(AppearanceManager.RecordingMode.allCases, id: \.self) { mode in
                HStack {
                    Image(systemName: mode.icon)
                        .foregroundColor(.blue)
                    Text(mode.description)
                }
                .tag(mode)
            }
        }
        .pickerStyle(.menu)
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
