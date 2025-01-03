//
//  CommandButtonView.swift
//  Zap
//
//  Created by Zigao Wang on 10/18/24.
//

import SwiftUI
import AVFoundation

struct CommandButton: View {
    @ObservedObject var viewModel: NotesViewModel
    @Environment(\.colorScheme) var colorScheme
    @State private var isRecording = false
    @State private var isExpanded = false
    @State private var activeButton: Int? = nil
    
    private let hapticImpact = UIImpactFeedbackGenerator(style: .medium)
    private let buttonSize: CGFloat = IconSize.large
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    ForEach(Array(zip([0,1,2], [
                        ("text.bubble.fill", Color.green, { viewModel.showTextNoteInput() }),
                        ("camera.fill", Color.orange, { viewModel.capturePhoto() }),
                        ("photo.on.rectangle.fill", Color.purple, { viewModel.showImagePicker() })
                    ])), id: \.0) { index, item in
                        Spacer()
                        Button(action: {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                activeButton = index
                            }
                            hapticImpact.impactOccurred()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                item.2()
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                    activeButton = nil
                                }
                            }
                        }) {
                            Circle()
                                .fill(item.1.opacity(0.15))
                                .frame(width: 50, height: 50)
                                .overlay(
                                    Image(systemName: item.0)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: buttonSize, height: buttonSize)
                                        .foregroundColor(item.1)
                                )
                                .scaleEffect(activeButton == index ? 0.9 : 1.0)
                        }
                    }
                    
                    Spacer()
                    
                    // Audio Button with Long Press Gesture
                    Circle()
                        .fill(isRecording ? Color.red.opacity(0.15) : Color.blue.opacity(0.15))
                        .frame(width: 50, height: 50)
                        .overlay(
                            Image(systemName: isRecording ? "stop.circle.fill" : "mic.circle.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: buttonSize, height: buttonSize)
                                .foregroundColor(isRecording ? .red : .blue)
                        )
                        .scaleEffect(isRecording ? 1.1 : 1.0)
                        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isRecording)
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { _ in
                                    if !isRecording {
                                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                            hapticImpact.impactOccurred()
                                            viewModel.startRecording()
                                            isRecording = true
                                            isExpanded = true
                                        }
                                    }
                                }
                                .onEnded { _ in
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                        hapticImpact.impactOccurred()
                                        viewModel.stopRecording()
                                        isRecording = false
                                        isExpanded = false
                                    }
                                }
                        )
                    
                    Spacer()
                }
                .padding(.vertical, 12)
            }
            .background(
                RoundedRectangle(cornerRadius: 32)
                    .fill(colorScheme == .dark ? 
                        Color(.systemGray6).opacity(0.95) : 
                        Color(.systemBackground).opacity(0.95)
                    )
                    .shadow(
                        color: Color(.systemGray4).opacity(0.3),
                        radius: 15,
                        x: 0,
                        y: 5
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 32)
                    .stroke(
                        Color(.systemGray4).opacity(0.2),
                        lineWidth: 0.5
                    )
            )
            .padding(.horizontal, 16)
            .position(x: geometry.size.width / 2, y: geometry.size.height - 20)
        }
        .ignoresSafeArea(.keyboard)
    }
}

// Preview provider
struct CommandButton_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            CommandButton(viewModel: NotesViewModel())
                .preferredColorScheme(.light)
                .frame(height: 140)
            CommandButton(viewModel: NotesViewModel())
                .preferredColorScheme(.dark)
                .frame(height: 140)
        }
    }
}
