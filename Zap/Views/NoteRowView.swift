//
//  NoteRowView.swift
//  Zap
//
//  Created by Zigao Wang on 9/21/24.
//

import SwiftUI
import AVKit

struct NoteRowView: View {
    @EnvironmentObject var viewModel: NotesViewModel
    @EnvironmentObject var appearanceManager: AppearanceManager
    @Environment(\.colorScheme) var colorScheme
    let note: NoteItem
    @State private var showFullScreen = false
    @State private var isEditing = false
    @State private var editedContent = ""
    @State private var isExpanded = false

    var body: some View {
        ZStack {
            HStack(spacing: 12) {
                completionButton

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        noteTypeIcon
                        Text(note.timestamp, style: .time)
                            .font(.caption)
                            .foregroundColor(.white)
                        Spacer()
                        editButton
                        deleteButton
                    }

                    if isEditing {
                        // Use TextEditor instead of TextField for multiline input
                        TextEditor(text: $editedContent)
                            .frame(minHeight: 100) // Increase the height here
                            .padding()
                            .border(Color.gray, width: 1) // Optional border for styling
                            .cornerRadius(10) // Optional rounded corners
                            .onSubmit {
                                saveEdits()
                                isEditing = false
                            }
                    } else {
                        noteContent
                    }
                }
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(noteBackgroundColor)
            .cornerRadius(16)
            .shadow(color: noteBackgroundColor.opacity(0.3), radius: 5, x: 0, y: 3)
            .opacity(note.isCompleted ? 0.7 : 1)
            .padding(.vertical, 6)
            .animation(.spring(response: 0.3, dampingFraction: 0.6, blendDuration: 0), value: note.isCompleted)
            .fullScreenCover(isPresented: $showFullScreen) {
                FullScreenMediaView(note: note, isPresented: $showFullScreen)
            }
            .swipeActions(edge: .leading) {
                Button {
                    viewModel.toggleNoteCompletion(note)
                } label: {
                    Label(note.isCompleted ? "Uncomplete" : "Complete", systemImage: note.isCompleted ? "xmark.circle" : "checkmark.circle")
                }
                .tint(note.isCompleted ? .orange : .green)
            }
            .swipeActions(edge: .trailing) {
                Button(role: .destructive) {
                    viewModel.deleteNote(note)
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }

            // Transcribing Indicator
            if note.isTranscribing {
                ZStack {
                    Color.black.opacity(0.4)
                        .cornerRadius(16)
                        .frame(height: 80)
                    ProgressView("Transcribing...")
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .foregroundColor(.white)
                }
            }
        }
    }

    private var completionButton: some View {
        Button(action: {
            viewModel.toggleNoteCompletion(note)
        }) {
            Image(systemName: note.isCompleted ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 24))
                .foregroundColor(.white)
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var noteTypeIcon: some View {
        Image(systemName: noteTypeIconName)
            .foregroundColor(.white)
            .font(.system(size: 16))
    }

    private var noteTypeIconName: String {
        switch note.type {
        case .text: return "text.bubble.fill"
        case .audio: return "mic.circle.fill"
        case .photo: return "camera.fill"
        }
    }

    private var noteBackgroundColor: Color {
        switch note.type {
        case .text: return .green
        case .audio: return .blue
        case .photo: return .orange
        }
    }

    private var editButton: some View {
        Group {
            if isEditable {
                Button(action: {
                    if isEditing {
                        saveEdits()
                    } else {
                        editedContent = contentToEdit
                    }
                    isEditing.toggle()
                }) {
                    Image(systemName: isEditing ? "checkmark.circle" : "pencil")
                        .resizable()
                        .scaledToFit()
                        .frame(width: IconSize.small, height: IconSize.small)
                        .foregroundColor(.white)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }

    private var noteContent: some View {
        VStack {
            switch note.type {
            case .text(let content):
                VStack(alignment: .leading) {
                    Text(content)
                        .foregroundColor(.white)
                        .lineLimit(isExpanded ? nil : 3)
                        .onTapGesture {
                            withAnimation {
                                isExpanded.toggle()
                            }
                        }
                }
            case .photo(let fileName):
                let url = getDocumentsDirectory().appendingPathComponent(fileName)
                Image(uiImage: UIImage(contentsOfFile: url.path) ?? UIImage())
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 200)
                    .cornerRadius(8)
                    .contentShape(Rectangle()) // Define precise tap area
                    .onTapGesture {
                        showFullScreen = true
                    }
                    .zIndex(1) // Lower z-index for image
            case .audio(_, _):
                VStack(alignment: .leading, spacing: 4) {
                    AudioPlayerInlineView(note: note)
                        .accentColor(.white)
                        .tint(.white)
                    if let transcription = note.transcription {
                        Text(transcription)
                            .lineLimit(isExpanded ? nil : 2)
                            .font(.system(size: 14))
                            .foregroundColor(.white)
                            .onTapGesture {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    isExpanded.toggle()
                                }
                            }
                        if transcription.count > 100 && !isExpanded {
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    isExpanded.toggle()
                                }
                            }) {
                                Text("Show More")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.8))
                            }
                        } else if isExpanded {
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    isExpanded.toggle()
                                }
                            }) {
                                Text("Show Less")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.8))
                            }
                        }
                    }
                }
            }
        }
    }

    private var isEditable: Bool {
        switch note.type {
        case .text, .audio: return true
        default: return false
        }
    }

    private var contentToEdit: String {
        switch note.type {
        case .text(let content): return content
        case .audio: return note.transcription ?? ""
        default: return ""
        }
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.minute, .second]
        formatter.unitsStyle = .positional
        formatter.zeroFormattingBehavior = .pad
        return formatter.string(from: duration) ?? "0:00"
    }

    private func saveEdits() {
        switch note.type {
        case .text:
            viewModel.editTextNote(note, newText: editedContent)
        case .audio:
            viewModel.editAudioTranscription(note, newTranscription: editedContent)
        default:
            break
        }
    }

    private var deleteButton: some View {
        Button(action: {
            viewModel.deleteNote(note)
        }) {
            Image(systemName: "trash")
                .foregroundColor(.white)
        }
        .zIndex(3) // Highest z-index for delete button
    }

    private func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
}

extension NoteType {
    var isAudio: Bool {
        if case .audio = self {
            return true
        }
        return false
    }
}
