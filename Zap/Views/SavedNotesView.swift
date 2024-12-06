//
//  SavedNotesView.swift
//  Zap
//
//  Created by Zigao Wang on 9/21/24.
//

import SwiftUI

struct SavedNotesView: View {
    @StateObject var viewModel = NotesViewModel()
    @EnvironmentObject var appearanceManager: AppearanceManager
    
    var body: some View {
        NavigationView {
            List {
                ForEach(viewModel.notes) { note in
                    NoteRowView(note: note)
                }
                .onDelete(perform: deleteNotes)
            }
            .navigationTitle("Saved Notes")
            .toolbar {
                EditButton()
            }
        }
    }
    
    private func deleteNotes(at offsets: IndexSet) {
        viewModel.notes.remove(atOffsets: offsets)
        viewModel.saveNotes()
    }
}

struct SavedNotesView_Previews: PreviewProvider {
    static var previews: some View {
        SavedNotesView()
            .environmentObject(AppearanceManager())
    }
}
