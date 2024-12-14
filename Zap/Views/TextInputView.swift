//
//  TextInputView.swift
//  Zap
//
//  Created by Zigao Wang on 10/20/24.
//

import SwiftUI

struct TextInputView: View {
    @Binding var content: String
    var onSave: () -> Void
    @State private var showingCancelAlert = false
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        NavigationView {
            TextEditor(text: $content)
                .padding()
                .navigationBarTitle("New Note", displayMode: .inline)
                .navigationBarItems(
                    leading: Button("Cancel") {
                        if !content.isEmpty {
                            showingCancelAlert = true
                        } else {
                            content = ""
                            onSave()
                        }
                    },
                    trailing: Button("Save") {
                        onSave()
                    }
                )
                .alert(isPresented: $showingCancelAlert) {
                    Alert(
                        title: Text("Discard Changes?"),
                        message: Text("Are you sure you want to discard your note?"),
                        primaryButton: .destructive(Text("Discard")) {
                            content = ""
                            onSave()
                        },
                        secondaryButton: .cancel()
                    )
                }
        }
    }
}
