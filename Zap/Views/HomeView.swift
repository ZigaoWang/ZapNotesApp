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
    @State private var showingDeleteAlert = false
    @State private var noteToDelete: NoteItem?
    
    let tabs = ["All", "Text", "Audio", "Photo", "Video"]

    private let joystickSize: CGFloat = 160
    private let bottomPadding: CGFloat = 20
    
    var body: some View {
        NavigationView {
            ZStack {
                VStack(spacing: 0) {
                    // Top bar with logo, title, date, and icons
                    HStack {
                        HStack(spacing: 8) {
                            Image("ZapLogo")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 30, height: 30)
                                .cornerRadius(6)
                            
                            Text("Zap Notes")
                                .font(.title2.bold())
                        }
                        
                        Spacer()
                        
                        Text(formattedDate())
                            .font(.subheadline)
                        
                        Button(action: {
                            viewModel.organizeAndPlanNotes()
                        }) {
                            Image(systemName: "wand.and.stars")
                                .foregroundColor(.white)
                                .padding(8)
                                .background(appearanceManager.accentColor)
                                .clipShape(Circle())
                        }
                        .buttonStyle(PlainButtonStyle())
                        .disabled(viewModel.isOrganizing)
                        
                        Button(action: {}) {
                            Image(systemName: "magnifyingglass")
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

                    Toggle("Show AI Organized Notes", isOn: $viewModel.isShowingAIOrganized)
                        .padding()

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

                    // Notes list
                    ScrollView {
                        LazyVStack(spacing: 4) {
                            ForEach(viewModel.isShowingAIOrganized ? viewModel.aiOrganizedNotes : filteredNotes) { note in
                                NoteRowView(note: note)
                                    .padding(.horizontal, 16)
                            }
                        }
                        .padding(.bottom, joystickSize + bottomPadding * 2)
                    }
                }
                
                // CommandButton (joystick)
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        CommandButton(viewModel: viewModel)
                            .frame(width: joystickSize, height: joystickSize)
                            .background(Color.clear)
                            .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 2)
                        Spacer()
                    }
                    .padding(.bottom, bottomPadding)
                }
            }
            .navigationBarHidden(true)
        }
        .accentColor(appearanceManager.accentColor)
                .font(.system(size: appearanceManager.fontSizeValue))
                .environmentObject(viewModel)
                .sheet(isPresented: $showingSettings) {
                    SettingsView().environmentObject(appearanceManager)
                }
                .overlay(
                    Group {
                        if viewModel.isOrganizing {
                            ProgressView("Organizing notes...")
                                .padding()
                                .background(Color(.systemBackground))
                                .cornerRadius(10)
                                .shadow(radius: 10)
                        }
                    }
                )
                .sheet(isPresented: $viewModel.showingTextInput) {
                    TextInputView(content: $viewModel.textInputContent, onSave: {
                        viewModel.addTextNote(viewModel.textInputContent)
                        viewModel.textInputContent = ""
                        viewModel.showingTextInput = false
                    })
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
                .sheet(isPresented: $viewModel.showingVideoRecorder) {
                    VideoPicker { videoURL in
                        viewModel.handleCapturedVideo(videoURL)
                    }
                }
                .alert(item: $viewModel.errorMessage) { errorMessage in
                    Alert(title: Text("Error"), message: Text(errorMessage.message), dismissButton: .default(Text("OK")))
                }
            }
            
            private var filteredNotes: [NoteItem] {
                let notesToFilter = viewModel.isShowingAIOrganized ? viewModel.aiOrganizedNotes : viewModel.notes
                switch selectedTab {
                case "All":
                    return notesToFilter
                case "Text":
                    return notesToFilter.filter { if case .text = $0.type { return true } else { return false } }
                case "Audio":
                    return notesToFilter.filter { if case .audio = $0.type { return true } else { return false } }
                case "Photo":
                    return notesToFilter.filter { if case .photo = $0.type { return true } else { return false } }
                case "Video":
                    return notesToFilter.filter { if case .video = $0.type { return true } else { return false } }
                default:
                    return notesToFilter
                }
            }

            private func formattedDate() -> String {
                let formatter = DateFormatter()
                formatter.dateFormat = "MMM d, yyyy"
                return formatter.string(from: Date())
            }
        }

        struct HomeView_Previews: PreviewProvider {
            static var previews: some View {
                HomeView()
                    .environmentObject(AppearanceManager())
            }
        }
