//
//  AudioNoteView.swift
//  Zap
//
//  Created by Zigao Wang on 9/21/24.
//

import SwiftUI
import AVFoundation

struct AudioNoteView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var viewModel: NotesViewModel
    @State private var isRecording = false
    @State private var audioRecorder: AVAudioRecorder?
    @State private var audioFilename: URL?

    var body: some View {
        VStack {
            if isRecording {
                Text("Recording...")
                    .foregroundColor(.red)
                    .padding()
            } else {
                Text("Tap to Record")
                    .foregroundColor(.green)
                    .padding()
            }

            Button(action: {
                if isRecording {
                    stopRecording()
                } else {
                    startRecording()
                }
            }) {
                Image(systemName: isRecording ? "stop.circle.fill" : "mic.circle.fill")
                    .resizable()
                    .frame(width: 100, height: 100)
                    .foregroundColor(isRecording ? .red : .green)
            }
            .padding()

            if viewModel.isTranscribing {
                ProgressView("Transcribing...")
                    .padding()
            }

            Spacer()
        }
        .navigationTitle("New Audio Note")
        .navigationBarTitleDisplayMode(.inline)
    }

    func startRecording() {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .default, options: [.allowBluetooth])
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)

            let documentsDirectory = FileManager.default.urls(
                for: .documentDirectory, in: .userDomainMask
            )[0]
            let filename = UUID().uuidString + ".m4a"
            let fileURL = documentsDirectory.appendingPathComponent(filename)
            audioFilename = fileURL

            let settings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 44100,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue,
                AVEncoderBitRateKey: 128000
            ]

            audioRecorder = try AVAudioRecorder(url: fileURL, settings: settings)
            audioRecorder?.prepareToRecord() // Prepare before recording
            let success = audioRecorder?.record() ?? false
            
            if success {
                // Update UI state on main thread
                DispatchQueue.main.async {
                    self.isRecording = true
                }
                print("[INFO] Started recording to \(filename)")
            } else {
                print("[ERROR] Failed to start recording")
            }
        } catch {
            print("[ERROR] Recording failed: \(error.localizedDescription)")
        }
    }

    func stopRecording() {
        guard let recorder = audioRecorder, let url = audioFilename else {
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
        
        // Create local copy to avoid closure capture issues
        let localURL = url
        
        Task { @MainActor in
            do {
                // Ensure audio session is deactivated properly
                try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
                
                // Add delay to ensure file is finalized
                try await Task.sleep(nanoseconds: 800_000_000) // 0.8 seconds
                
                // Verify file exists
                let fileManager = FileManager.default
                guard fileManager.fileExists(atPath: localURL.path) else {
                    print("[ERROR] Audio file does not exist at path: \(localURL.path)")
                    audioRecorder = nil
                    audioFilename = nil
                    presentationMode.wrappedValue.dismiss()
                    return
                }
                
                // Get file attributes to check size
                let attributes = try fileManager.attributesOfItem(atPath: localURL.path)
                let fileSize = attributes[.size] as? UInt64 ?? 0
                
                if fileSize == 0 {
                    print("[ERROR] Audio file is empty (0 bytes)")
                    audioRecorder = nil
                    audioFilename = nil
                    presentationMode.wrappedValue.dismiss()
                    return
                }
                
                // Check duration
                let asset = AVURLAsset(url: localURL)
                let duration = CMTimeGetSeconds(asset.duration)
                
                print("[INFO] Recorded audio duration: \(duration) seconds, size: \(fileSize) bytes")
                
                if duration > 0 {
                    viewModel.addAudioNote(fileName: localURL.lastPathComponent, duration: duration)
                } else {
                    print("[ERROR] Recorded audio has zero duration")
                }
                
                presentationMode.wrappedValue.dismiss()
            } catch {
                print("[ERROR] Error finalizing recording: \(error)")
                presentationMode.wrappedValue.dismiss()
            }
            
            audioRecorder = nil
            audioFilename = nil
        }
    }
}
