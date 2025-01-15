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
    @FocusState private var isFocused: Bool

    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    if !content.isEmpty {
                        showingCancelAlert = true
                    } else {
                        content = ""
                        onSave()
                    }
                }
            
            VStack(spacing: 0) {
                Spacer()
                
                VStack(spacing: 0) {
                    HStack {
                        Button("Cancel") {
                            if !content.isEmpty {
                                showingCancelAlert = true
                            } else {
                                content = ""
                                onSave()
                            }
                        }
                        .foregroundColor(.red)
                        
                        Spacer()
                        
                        Text("New Note")
                            .font(.headline)
                        
                        Spacer()
                        
                        Button("Save") {
                            onSave()
                        }
                        .foregroundColor(.blue)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 12)
                    
                    Divider()
                    
                    TextField("Write something...", text: $content)
                        .font(.body)
                        .padding(.horizontal)
                        .padding(.vertical, 12)
                        .focused($isFocused)
                        .multilineTextAlignment(.leading)
                }
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
            .padding(.horizontal)
            .padding(.bottom, 12)
        }
        .onAppear {
            isFocused = true
        }
        .alert("Discard Changes?", isPresented: $showingCancelAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Discard", role: .destructive) {
                content = ""
                onSave()
            }
        } message: {
            Text("Are you sure you want to discard your note?")
        }
    }
}
