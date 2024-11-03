//
//  SettingsView.swift
//  Zap
//
//  Created by Zigao Wang on 9/27/24.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var appearanceManager: AppearanceManager
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Account")) {
                    if let email = authManager.currentUser?.email {
                        Text("Signed in as: \(email)")
                    }
                    Button("Sign Out") {
                        authManager.logout()
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(.red)
                }
                
                NavigationLink(destination: AppearanceSettingsView()) {
                    SettingsRowView(title: "Appearance", icon: "paintbrush.fill")
                }
                
                NavigationLink(destination: AboutHelpView()) {
                    SettingsRowView(title: "About & Help", icon: "info.circle.fill")
                }
            }
            .navigationTitle("Settings")
        }
    }
}

struct SettingsRowView: View {
    let title: String
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
            Text(title)
        }
    }
}
