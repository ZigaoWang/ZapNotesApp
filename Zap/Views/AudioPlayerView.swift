//
//  AudioPlayerView.swift
//  Zap
//
//  Created by Zigao Wang on 9/21/24.
//

import SwiftUI
import AVKit

struct AudioPlayerView: View {
    let url: URL
    
    @State private var player: AVPlayer?
    @State private var isPlaying = false
    @State private var progress: Double = 0
    @State private var duration: Double = 0
    @State private var timeObserver: Any?
    
    var body: some View {
        VStack {
            HStack {
                Button(action: togglePlayPause) {
                    Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.title)
                }
                
                Slider(value: $progress, in: 0...duration) { editing in
                    if !editing {
                        seek(to: progress)
                    }
                }
                
                Text(formatTime(progress))
                    .font(.caption)
            }
            .padding()
        }
        .onAppear {
            setupAudio()
        }
        .onDisappear {
            cleanup()
        }
    }
    
    private func setupAudio() {
        // Configure audio session for speaker playback
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
            try AVAudioSession.sharedInstance().overrideOutputAudioPort(.speaker)
        } catch {
            print("Failed to set audio session: \(error)")
        }
        
        // Create player
        let playerItem = AVPlayerItem(url: url)
        player = AVPlayer(playerItem: playerItem)
        
        // Get duration
        let seconds = playerItem.asset.duration.seconds
        duration = seconds.isFinite ? seconds : 0
        
        // Add time observer
        let interval = CMTime(seconds: 0.1, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserver = player?.addPeriodicTimeObserver(forInterval: interval, queue: .main) { time in
            let currentTime = time.seconds
            progress = currentTime
        }
        
        // Add notification for when playback ends
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: playerItem,
            queue: .main
        ) { _ in
            DispatchQueue.main.async {
                isPlaying = false
                progress = 0
                player?.seek(to: .zero)
            }
        }
        
        // Prepare for playback
        player?.seek(to: .zero)
        player?.volume = 1.0
    }
    
    private func togglePlayPause() {
        guard let player = player else { return }
        
        if isPlaying {
            player.pause()
        } else {
            if progress >= duration {
                seek(to: 0)
            }
            player.play()
        }
        isPlaying.toggle()
    }
    
    private func seek(to time: Double) {
        let cmTime = CMTime(seconds: time, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        player?.seek(to: cmTime)
    }
    
    private func cleanup() {
        if let timeObserver = timeObserver {
            player?.removeTimeObserver(timeObserver)
        }
        NotificationCenter.default.removeObserver(self)
        player?.pause()
        
        // Deactivate audio session
        do {
            try AVAudioSession.sharedInstance().setActive(false)
        } catch {
            print("Failed to deactivate audio session: \(error)")
        }
        
        player = nil
    }
    
    private func formatTime(_ time: Double) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
