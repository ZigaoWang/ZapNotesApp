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

    var body: some View {
        TextInputView(content: $noteText) {
            if !noteText.isEmpty {
                viewModel.addTextNote(noteText)
            }
            presentationMode.wrappedValue.dismiss()
        }
    }
}
