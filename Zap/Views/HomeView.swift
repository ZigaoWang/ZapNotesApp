//
// HomeView.swift
// Zap
//
// Created by Zigao Wang on 9/21/24.
//

import SwiftUI
import AVFoundation

struct HomeView: View {
    @StateObject var viewModel = NotesViewModel()
    @EnvironmentObject var appearanceManager: AppearanceManager
    @State private var showingSettings = false
    @State private var selectedTab = "All"
    @State private var isOrganizing = false
    @State private var showingDeleteAlert = false
    @State private var noteToDelete: NoteItem?
    
    let tabs = ["All", "Text", "Audio", "Photo"]

    private let joystickSize: CGFloat = 160
    private let bottomPadding: CGFloat = 20
    
    var body: some View {
        NavigationView {
            ZStack {
                VStack(spacing: 0) {
                    // Top bar with logo, title, date, and icons
                    HStack {
                        HStack(spacing: 10) {
                            Image("ZapLogo")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 32, height: 32)
                                .cornerRadius(8)
                            
                            Text("Zap Notes")
                                .font(.title3.bold())
                        }
                        
                        Spacer()
                        
                        Text(formattedDate())
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 12)
                        
                        Button(action: {
                            organizeAndPlanNotes()
                        }) {
                            Image(systemName: "wand.and.stars")
                                .font(.system(size: 16))
                                .foregroundColor(.white)
                                .padding(10)
                                .background(viewModel.isOrganizing ? Color.gray : appearanceManager.accentColor)
                                .clipShape(Circle())
                        }
                        .buttonStyle(PlainButtonStyle())
                        .disabled(viewModel.isOrganizing)
                        
                        if viewModel.canUndo {
                            Button(action: {
                                viewModel.undoOrganization()
                            }) {
                                Image(systemName: "arrow.uturn.backward")
                                    .font(.system(size: 16))
                                    .foregroundColor(.white)
                                    .padding(10)
                                    .background(appearanceManager.accentColor)
                                    .clipShape(Circle())
                            }
                            .buttonStyle(PlainButtonStyle())
                            .transition(.scale)
                        }
                        
                        Button(action: {
                            showingSettings = true
                        }) {
                            Image(systemName: "gear")
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 12)
                    .background(Color(.systemBackground))

                    // Tab bar
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(tabs, id: \.self) { tab in
                                Button(action: {
                                    selectedTab = tab
                                }) {
                                    Text(tab)
                                        .padding(.vertical, 6)
                                        .padding(.horizontal, 10)
                                        .background(selectedTab == tab ? appearanceManager.accentColor : Color.clear)
                                        .foregroundColor(selectedTab == tab ? .white : .primary)
                                        .cornerRadius(12)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical, 8)
                    .background(Color(.systemBackground))

                    // Notes list with empty state
                    ScrollView {
                        if filteredNotes.isEmpty {
                            GeometryReader { geometry in
                                EmptyStateView()
                                    .frame(width: geometry.size.width, height: geometry.size.height)
                                    .offset(y: geometry.size.height / 2.5)
                            }
                            .frame(height: UIScreen.main.bounds.height - 580)
                        } else {
                            LazyVStack(spacing: 4) {
                                ForEach(filteredNotes) { note in
                                    NoteRowView(note: note)
                                        .padding(.horizontal, 16)
                                }
                            }
                            .padding(.bottom, 100) // Adjusted padding for bottom bar
                        }
                    }
                }
                
                // Organization progress overlay
                if viewModel.showOrganizationProgress {
                    Color.black.opacity(0.4)
                        .edgesIgnoringSafeArea(.all)
                        .transition(.opacity)
                    
                    VStack(spacing: 20) {
                        Spacer()
                        VStack(spacing: 20) {
                            ProgressView()
                                .scaleEffect(1.2)
                                .tint(.white)
                            
                            Text(viewModel.organizationStatus)
                                .font(.headline)
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(.horizontal, 30)
                        .padding(.vertical, 25)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color(.systemBackground).opacity(0.95))
                                .shadow(color: Color.black.opacity(0.2), radius: 15, x: 0, y: 10)
                        )
                        .padding(.horizontal, 40)
                        Spacer()
                    }
                    .transition(.opacity.combined(with: .scale))
                }
                
                if viewModel.errorMessage != nil {
                    VStack {
                        Spacer()
                        HStack(spacing: 12) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.white)
                            Text(viewModel.errorMessage!)
                                .foregroundColor(.white)
                                .font(.system(size: 16, weight: .medium))
                                .multilineTextAlignment(.center)
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.red.opacity(0.9))
                                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                        )
                        .padding(.horizontal, 20)
                        .padding(.bottom, 100)
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                
                // Command buttons at bottom
                VStack {
                    Spacer()
                    CommandButton(viewModel: viewModel)
                }
            }
            .navigationBarHidden(true)
        }
        .accentColor(appearanceManager.accentColor)
        .environmentObject(viewModel)
        .sheet(isPresented: $showingSettings) {
            SettingsView().environmentObject(appearanceManager)
        }
        .sheet(isPresented: $viewModel.showingTextInput) {
            TextInputView(content: $viewModel.textInputContent) {
                if !viewModel.textInputContent.isEmpty {
                    viewModel.addTextNote(viewModel.textInputContent)
                }
                viewModel.textInputContent = ""
                viewModel.showingTextInput = false
            }
        }
        .sheet(isPresented: $viewModel.showingImagePicker) {
            ImagePicker(sourceType: .photoLibrary) { image in
                viewModel.handleCapturedImage(image)
            }
        }
        .sheet(isPresented: $viewModel.showingCamera) {
            ImagePicker(sourceType: .camera) { image in
                viewModel.handleCapturedImage(image)
            }
        }
    }
    
    private var filteredNotes: [NoteItem] {
        let notes = viewModel.notes
        
        switch selectedTab {
        case "All":
            return notes
        case "Text":
            return notes.filter { if case .text = $0.type { return true } else { return false } }
        case "Audio":
            return notes.filter { if case .audio = $0.type { return true } else { return false } }
        case "Photo":
            return notes.filter { if case .photo = $0.type { return true } else { return false } }
        default:
            return notes
        }
    }

    private func formattedDate() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: Date())
    }

    private func organizeAndPlanNotes() {
        if viewModel.notes.isEmpty {
            // Show a temporary alert or message when there are no notes
            withAnimation {
                viewModel.errorMessage = "No notes to organize. Add some notes first!"
            }
            // Hide the message after a delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                withAnimation {
                    viewModel.errorMessage = nil
                }
            }
            return
        }
        
        viewModel.organizeAndPlanNotes()
    }

    private func deleteNotes(at offsets: IndexSet) {
        for index in offsets {
            let noteToDelete = filteredNotes[index]
            self.noteToDelete = noteToDelete
            showingDeleteAlert = true
        }
    }
}

struct AlertItem: Identifiable {
    let id = UUID()
    let message: String
}

// Add this new view
struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "note.text")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("No Notes Yet")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            Text("Start by adding your first note using the button below")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
