//
//  NoteItem.swift
//  Zap
//
//  Created by Zigao Wang on 9/22/24.
//

import Foundation

struct NoteItem: Identifiable, Codable {
    let id: UUID
    let timestamp: Date
    var type: NoteType
    var isCompleted: Bool
    var transcription: String?
    var isTranscribing: Bool

    init(id: UUID = UUID(), timestamp: Date = Date(), type: NoteType, isCompleted: Bool = false, transcription: String? = nil, isTranscribing: Bool = false) {
        self.id = id
        self.timestamp = timestamp
        self.type = type
        self.isCompleted = isCompleted
        self.transcription = transcription
        self.isTranscribing = isTranscribing
    }
}

enum NoteType: Codable {
    case text(String)
    case audio(String, TimeInterval)
    case photo(String)
    case video(String, TimeInterval)
}
