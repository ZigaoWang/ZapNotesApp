//
//  ZapApp.swift
//  Zap
//
//  Created by Zigao Wang on 9/18/24.
//

import SwiftUI

@main
struct ZapApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                #if os(macOS)
                .frame(minWidth: 800, minHeight: 600)
                #endif
        }
        #if os(macOS)
        .windowStyle(HiddenTitleBarWindowStyle())
        .windowToolbarStyle(.unified)
        #endif
    }
}
