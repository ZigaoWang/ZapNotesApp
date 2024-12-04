//
//  EditNoteView.swift
//  Zap
//
//  Created by Zigao Wang on 10/20/24.
//

import SwiftUI

struct EditNoteView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var editedContent: String
    let note: NoteItem
    let onSave: (NoteItem) -> Void

    init(note: NoteItem, onSave: @escaping (NoteItem) -> Void) {
        self.note = note
        self.onSave = onSave
        
        switch note.type {
        case .text(let content):
            _editedContent = State(initialValue: content)
        case .audio(_, _), .photo(_):
            _editedContent = State(initialValue: note.transcription ?? "")
        default:
            fatalError("Unsupported note type")
        }
    }

    var body: some View {
        NavigationView {
            TextEditor(text: $editedContent)
                .padding()
                .navigationBarTitle("Edit Note", displayMode: .inline)
                .navigationBarItems(
                    leading: Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    },
                    trailing: Button("Save") {
                        var updatedNote = note
                        switch updatedNote.type {
                        case .text:
                            updatedNote.type = .text(editedContent)
                        case .audio, .photo:
                            updatedNote.transcription = editedContent
                        default:
                            fatalError("Unsupported note type")
                        }
                        onSave(updatedNote)
                        presentationMode.wrappedValue.dismiss()
                    }
                )
        }
    }
}
