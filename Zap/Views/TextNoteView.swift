//
//  TextNoteView.swift
//  Zap
//
//  Created by Zigao Wang on 9/21/24.
//

import SwiftUI

struct TextNoteView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var viewModel: NotesViewModel
    @State private var noteText = ""
    @State private var showingCancelAlert = false

    var body: some View {
        NavigationView {
            TextEditor(text: $noteText)
                .padding()
                .navigationBarTitle("New Text Note", displayMode: .inline)
                .navigationBarItems(
                    leading: Button("Cancel") {
                        if !noteText.isEmpty {
                            showingCancelAlert = true
                        } else {
                            presentationMode.wrappedValue.dismiss()
                        }
                    },
                    trailing: Button("Save") {
                        viewModel.addTextNote(noteText)
                        presentationMode.wrappedValue.dismiss()
                    }
                )
                .alert(isPresented: $showingCancelAlert) {
                    Alert(
                        title: Text("Discard Changes?"),
                        message: Text("Are you sure you want to discard your note?"),
                        primaryButton: .destructive(Text("Discard")) {
                            presentationMode.wrappedValue.dismiss()
                        },
                        secondaryButton: .cancel()
                    )
                }
        }
    }
}
