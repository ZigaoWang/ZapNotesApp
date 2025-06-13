//
//  NotesViewModel.swift
//  Zap
//
//  Created by Zigao Wang on 9/21/24.
//

import SwiftUI
import AVFoundation
import Speech
import NaturalLanguage
import Photos
import Foundation

class NotesViewModel: ObservableObject {
    @Published var notes: [NoteItem] = []
    @Published var isRecording = false
    @Published var isSummarizing = false
    @Published var summary: String = ""
    @Published var errorMessage: String? = nil
    @Published var showingTextInput = false
    @Published var textInputContent = ""
    @Published var showingImagePicker = false
    @Published var showingCamera = false
    @Published var isOrganizing = false
    @Published var isTranscribing = false
    @Published var previousNoteState: [NoteItem]? = nil
    @Published var canUndo = false
    @Published var organizationStatus: String = ""
    @Published var showOrganizationProgress = false
    
    private var audioRecorder: AVAudioRecorder?
    private var audioFileURL: URL?
    private let supportedLocales: [Locale] = [
        Locale(identifier: "en-US"),
        Locale(identifier: "zh-Hans")
    ]
    
    init() {
        loadNotes()
        setupAudioSession()
    }
    
    private func setupAudioSession() {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            // More reliable configuration with specific options
            try audioSession.setCategory(.playAndRecord, 
                                         mode: .default,
                                         options: [.allowBluetooth, .allowBluetoothA2DP, .defaultToSpeaker])
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("Failed to set up audio session: \(error)")
        }
    }
    
    // MARK: - Note Management
    
    func addTextNote(_ text: String) {
        let newNote = NoteItem(type: .text(text))
        notes.insert(newNote, at: 0)
        saveNotes()
    }
    
    func addAudioNote(fileName: String, duration: TimeInterval) {
        let newNote = NoteItem(type: .audio(fileName, duration))
        notes.insert(newNote, at: 0)
        saveNotes()
        
        // Start transcription asynchronously
        Task {
            isTranscribing = true
            await transcribeAudioNote(newNote)
            isTranscribing = false
        }
    }
    
    func addPhotoNote(fileName: String) {
        let newNote = NoteItem(type: .photo(fileName))
        notes.insert(newNote, at: 0)
        saveNotes()
    }
    
    func toggleNoteCompletion(_ note: NoteItem) {
        if let index = notes.firstIndex(where: { $0.id == note.id }) {
            notes[index].isCompleted.toggle()
            saveNotes()
        }
    }
    
    func deleteNotes(at offsets: IndexSet) {
        notes.remove(atOffsets: offsets)
        saveNotes()
    }
    
    func updateTranscription(for note: NoteItem, with transcription: String) {
        if let index = notes.firstIndex(where: { $0.id == note.id }) {
            notes[index].transcription = transcription
            saveNotes()
        }
    }
    
    // MARK: - Audio Recording
    
    func startRecording() {
        // Configure audio session specifically for recording
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .default, options: [.allowBluetooth])
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("Failed to configure audio session for recording: \(error)")
            return
        }
        
        // Create unique filename for recording
        let audioFilename = getDocumentsDirectory().appendingPathComponent("\(UUID().uuidString).m4a")
        audioFileURL = audioFilename
        
        // Higher quality recording settings
        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue,
            AVEncoderBitRateKey: 128000
        ]
        
        do {
            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            audioRecorder?.prepareToRecord() // Ensure recorder is ready
            let success = audioRecorder?.record() ?? false
            
            if success {
                // Update UI state on main thread
                DispatchQueue.main.async {
                    self.isRecording = true
                }
                print("[INFO] Started recording to \(audioFilename.lastPathComponent)")
            } else {
                print("[ERROR] Failed to start recording")
            }
        } catch {
            print("[ERROR] Could not start recording: \(error)")
        }
    }
    
    func stopRecording() {
        guard let recorder = audioRecorder, let audioURL = audioFileURL else {
            print("[WARNING] No active recorder or file URL found")
            // Update UI state on main thread
            DispatchQueue.main.async {
                self.isRecording = false
            }
            return
        }
        
        // Finalize recording properly
        recorder.stop()
        
        // Update UI state on main thread
        DispatchQueue.main.async {
            self.isRecording = false
        }
        
        // Create a local copy of URL to avoid closure capture issues
        let localAudioURL = audioURL
        
        Task { @MainActor in
            do {
                // Ensure audio session is deactivated properly
                try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
                
                // Add delay to ensure file is finalized
                try await Task.sleep(nanoseconds: 800_000_000) // 0.8 seconds
                
                // Verify file exists
                let fileManager = FileManager.default
                guard fileManager.fileExists(atPath: localAudioURL.path) else {
                    print("[ERROR] Audio file does not exist at path: \(localAudioURL.path)")
                    audioRecorder = nil
                    audioFileURL = nil
                    return
                }
                
                // Get file attributes to check size
                let attributes = try fileManager.attributesOfItem(atPath: localAudioURL.path)
                let fileSize = attributes[.size] as? UInt64 ?? 0
                
                if fileSize == 0 {
                    print("[ERROR] Audio file is empty (0 bytes)")
                    audioRecorder = nil
                    audioFileURL = nil
                    return
                }
                
                // Check duration
                let asset = AVAsset(url: localAudioURL)
                let duration = asset.duration.seconds
                
                print("[INFO] Recorded audio duration: \(duration) seconds, size: \(fileSize) bytes")
                
                if duration > 0 {
                    // Process valid audio file
                    addAudioNote(fileName: localAudioURL.lastPathComponent, duration: duration)
                    
                    // Start transcription asynchronously
                    Task {
                        await transcribeAudioNote(NoteItem(type: .audio(localAudioURL.lastPathComponent, duration)))
                    }
                } else {
                    print("[ERROR] Recorded audio has zero duration")
                }
            } catch {
                print("[ERROR] Error finalizing recording: \(error)")
            }
            
            audioRecorder = nil
            audioFileURL = nil
        }
    }
    
    // MARK: - Transcription
    
    func transcribeAudioNote(_ note: NoteItem) async {
        guard case .audio(let fileName, _) = note.type else { return }

        // Update the note's isTranscribing state on the main thread
        await MainActor.run {
            if let index = notes.firstIndex(where: { $0.id == note.id }) {
                notes[index].isTranscribing = true
                objectWillChange.send()
            }
        }

        do {
            let audioFileURL = getDocumentsDirectory().appendingPathComponent(fileName)
            let transcription = try await AIManager.shared.transcribeAudio(url: audioFileURL)

            // Update the transcription content on the main thread
            await MainActor.run {
                if let index = notes.firstIndex(where: { $0.id == note.id }) {
                    notes[index].transcription = transcription
                    notes[index].isTranscribing = false
                    saveNotes()
                }
            }
        } catch {
            print("Error transcribing audio: \(error)")
            // Ensure isTranscribing is set to false on error
            await MainActor.run {
                if let index = notes.firstIndex(where: { $0.id == note.id }) {
                    notes[index].isTranscribing = false
                }
            }
        }
    }
    
    // MARK: - Language Detection
    
    func detectLanguage(for text: String) -> String {
        let languageRecognizer = NLLanguageRecognizer()
        languageRecognizer.processString(text)
        guard let dominantLanguage = languageRecognizer.dominantLanguage else {
            return "Unknown"
        }
        switch dominantLanguage {
        case .english:
            return "English"
        case .simplifiedChinese, .traditionalChinese:
            return "Chinese"
        default:
            return "Other"
        }
    }
    
    // MARK: - Data Persistence
    
    func saveNotes() {
        do {
            let data = try JSONEncoder().encode(notes)
            // Save to file
            let url = getDocumentsDirectory().appendingPathComponent("notes.json")
            try data.write(to: url)
            
            // Also save to UserDefaults as backup
            UserDefaults.standard.set(data, forKey: "notes")
        } catch {
            print("Error saving notes: \(error)")
        }
    }
    
    private func loadNotes() {
        let url = getDocumentsDirectory().appendingPathComponent("notes.json")
        
        do {
            // Try loading from file first
            if let data = try? Data(contentsOf: url) {
                notes = try JSONDecoder().decode([NoteItem].self, from: data)
                return
            }
            
            // If file doesn't exist, try UserDefaults
            if let data = UserDefaults.standard.data(forKey: "notes") {
                notes = try JSONDecoder().decode([NoteItem].self, from: data)
                return
            }
        } catch {
            print("Error loading notes: \(error)")
            notes = [] // Initialize empty array if loading fails
        }
    }
    
    // MARK: - Helpers
    
    private func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    func editTextNote(_ note: NoteItem, newText: String) {
        if let index = notes.firstIndex(where: { $0.id == note.id }) {
            notes[index].type = .text(newText)
            saveNotes()
        }
    }

    func editAudioTranscription(_ note: NoteItem, newTranscription: String) {
        if let index = notes.firstIndex(where: { $0.id == note.id }) {
            notes[index].transcription = newTranscription
            saveNotes()
        }
    }
    
    // MARK: - AI Summarize
    
    func summarizeNotes() {
        Task {
            do {
                self.isSummarizing = true
                self.errorMessage = nil
                let newSummary = try await AIManager.shared.summarizeNotes(notes)
                await MainActor.run {
                    self.summary = newSummary
                    self.isSummarizing = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to generate summary: \(error.localizedDescription)"
                    self.isSummarizing = false
                }
            }
        }
    }
    
    func deleteNote(_ note: NoteItem) {
        notes.removeAll { $0.id == note.id }
        saveNotes()
    }
    
    func capturePhoto() {
        showingCamera = true
    }
    
    func showTextNoteInput() {
        showingTextInput = true
    }
    
    func showImagePicker() {
        showingImagePicker = true
    }
    
    func handleCapturedImage(_ image: UIImage) {
        if let data = image.jpegData(compressionQuality: 0.8) {
            let fileName = UUID().uuidString + ".jpg"
            let fileURL = getDocumentsDirectory().appendingPathComponent(fileName)
            try? data.write(to: fileURL)
            addPhotoNote(fileName: fileName)
        }
    }
    
    func organizeAndPlanNotes() {
        guard !notes.isEmpty else {
            errorMessage = "No notes available to organize"
            return
        }
        
        Task {
            do {
                await MainActor.run {
                    self.isOrganizing = true
                    self.errorMessage = nil
                    self.showOrganizationProgress = true
                    self.organizationStatus = "Analyzing notes..."
                }
                
                // Store current state before organizing
                let currentNotes = self.notes
                
                // Add a small delay to show the progress
                try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                
                await MainActor.run {
                    self.organizationStatus = "Reorganizing notes..."
                }
                
                let organizedNotes = try await AIManager.shared.organizeAndPlanNotes(notes)
                
                await MainActor.run {
                    if !organizedNotes.isEmpty {
                        self.organizationStatus = "Successfully reorganized \(organizedNotes.count) notes"
                        self.previousNoteState = currentNotes
                        self.notes = organizedNotes
                        self.canUndo = true
                        saveNotes()
                        
                        // Hide the progress after a short delay
                        Task {
                            try await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds
                            await MainActor.run {
                                self.showOrganizationProgress = false
                            }
                        }
                    } else {
                        self.organizationStatus = "Organization failed"
                        self.errorMessage = "Unable to process notes. Please try adding more detailed content."
                        
                        // Hide the error after 3 seconds
                        Task {
                            try await Task.sleep(nanoseconds: 3_000_000_000) // 3 seconds
                            await MainActor.run {
                                self.errorMessage = nil
                            }
                        }
                    }
                    self.isOrganizing = false
                    self.showOrganizationProgress = false
                }
            } catch {
                await MainActor.run {
                    self.organizationStatus = "Error occurred"
                    self.errorMessage = "Failed to organize notes: \(error.localizedDescription)"
                    self.isOrganizing = false
                    self.showOrganizationProgress = false
                    
                    // Hide the error after 3 seconds
                    Task {
                        try await Task.sleep(nanoseconds: 3_000_000_000) // 3 seconds
                        await MainActor.run {
                            self.errorMessage = nil
                        }
                    }
                }
            }
        }
    }

    func undoOrganization() {
        guard let previousState = previousNoteState else { return }
        notes = previousState
        saveNotes()
        previousNoteState = nil
        canUndo = false
    }
    
    func updateNote(_ updatedNote: NoteItem) {
        if let index = notes.firstIndex(where: { $0.id == updatedNote.id }) {
            notes[index] = updatedNote
            saveNotes()
        }
    }
}
