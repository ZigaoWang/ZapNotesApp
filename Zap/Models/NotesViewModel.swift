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
            try audioSession.setCategory(.playAndRecord, mode: .default)
            try audioSession.setActive(true)
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
        let audioFilename = getDocumentsDirectory().appendingPathComponent("\(UUID().uuidString).m4a")
        audioFileURL = audioFilename
        
        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        do {
            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            audioRecorder?.record()
            isRecording = true
        } catch {
            print("Could not start recording: \(error)")
        }
    }
    
    func stopRecording() {
        audioRecorder?.stop()
        isRecording = false
        
        if let audioURL = audioFileURL {
            let asset = AVAsset(url: audioURL)
            let duration = asset.duration.seconds
            addAudioNote(fileName: audioURL.lastPathComponent, duration: duration)
            
            // Start transcription asynchronously
            Task {
                await transcribeAudioNote(NoteItem(type: .audio(audioURL.lastPathComponent, duration)))
            }
        }
        
        audioRecorder = nil
        audioFileURL = nil
    }
    
    // MARK: - Transcription
    
func transcribeAudioNote(_ note: NoteItem) async {
        guard case .audio(let fileName, _) = note.type else { return }

        // 在主线程上更新对应笔记的 isTranscribing 状态为 true
        await MainActor.run {
            if let index = notes.firstIndex(where: { $0.id == note.id }) {
                notes[index].isTranscribing = true
                objectWillChange.send()
            }
        }

        do {
            let audioFileURL = getDocumentsDirectory().appendingPathComponent(fileName)
            let transcription = try await AIManager.shared.transcribeAudio(url: audioFileURL)

            // 更新转录内容，并将 isTranscribing 设为 false
            await MainActor.run {
                if let index = notes.firstIndex(where: { $0.id == note.id }) {
                    notes[index].transcription = transcription
                    notes[index].isTranscribing = false
                    saveNotes()
                }
            }
        } catch {
            print("Error transcribing audio: \(error)")
            // 确保在发生错误时也将 isTranscribing 设为 false
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
        Task {
            do {
                self.isOrganizing = true
                self.errorMessage = nil
                let organizedNotes = try await AIManager.shared.organizeAndPlanNotes(notes)
                await MainActor.run {
                    self.notes = organizedNotes // Replace existing notes
                    saveNotes() // Save immediately after updating
                    self.isOrganizing = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to organize notes: \(error.localizedDescription)"
                    self.isOrganizing = false
                }
            }
        }
    }

    func updateNote(_ updatedNote: NoteItem) {
        if let index = notes.firstIndex(where: { $0.id == updatedNote.id }) {
            notes[index] = updatedNote
            saveNotes()
        }
    }
}
