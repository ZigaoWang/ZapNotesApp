//
//  AIManager.swift
//  Zap
//
//  Created by Zigao Wang on 10/9/24.
//

import Foundation
import UIKit
import Vision
import os.log
import AVFoundation

class AIManager {
    static let shared = AIManager()
    private let apiBaseURL = URL(string: "https://api.zap.zigao.wang/api/openai")!

    private init() {
        // No need for API key in the frontend
    }

    func summarizeNotes(_ notes: [NoteItem]) async throws -> String {
        var messages: [[String: Any]] = [
            ["role": "system", "content": "Please summarize the following notes in a concise manner, using the same language as the input."]
        ]

        for note in notes {
            switch note.type {
            case .text(let content):
                messages.append(["role": "user", "content": content])
            case .photo(let fileName):
                if let image = loadImage(fileName: fileName),
                   let description = try await analyzeImage(image) {
                    messages.append(["role": "user", "content": "Image description: \(description)"])
                }
            case .audio(_, _):
                if let transcription = note.transcription {
                    messages.append(["role": "user", "content": "Audio transcription: \(transcription)"])
                }
            }
        }

        messages.append(["role": "user", "content": "Please summarize the main points of these notes."])
        
        return try await sendSummarizationRequest(messages: messages)
    }
    
    private func analyzeImage(_ image: UIImage) async throws -> String? {
        guard let imageData = compressImage(image) else {
            print("[ERROR] Failed to compress image")
            return nil
        }
        
        let boundary = UUID().uuidString
        var request = URLRequest(url: apiBaseURL.appendingPathComponent("process-notes"))
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        // Add text content
        let textContent = "Please analyze this image and provide a brief description. Only give me the description, do not give me anything else."
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"text\"\r\n\r\n".data(using: .utf8)!)
        body.append(textContent.data(using: .utf8)!)
        body.append("\r\n".data(using: .utf8)!)
        
        // Add image
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"images\"; filename=\"image.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n".data(using: .utf8)!)
        
        // Add closing boundary
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            print("[ERROR] Invalid response type")
            return nil
        }
        
        print("[INFO] HTTP Status Code: \(httpResponse.statusCode)")
        print("[DEBUG] Response Headers: \(httpResponse.allHeaderFields)")
        
        if !(200...299).contains(httpResponse.statusCode) {
            print("[ERROR] HTTP request failed: \(response)")
            if let responseString = String(data: data, encoding: .utf8) {
                print("[DEBUG] Response body: \(responseString)")
            }
            return nil
        }
        
        do {
            if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
               let choices = json["choices"] as? [[String: Any]],
               let firstChoice = choices.first,
               let message = firstChoice["message"] as? [String: Any],
               let content = message["content"] as? String {
                return content
            } else {
                print("[ERROR] Failed to parse image analysis response")
                if let responseString = String(data: data, encoding: .utf8) {
                    print("[DEBUG] Raw response: \(responseString)")
                }
                return nil
            }
        } catch {
            print("[ERROR] Error parsing JSON: \(error)")
            return nil
        }
    }
    
    private func sendSummarizationRequest(messages: [[String: Any]]) async throws -> String {
        var request = URLRequest(url: apiBaseURL.appendingPathComponent("chat"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody: [String: Any] = [
            "messages": messages,
            "max_tokens": 500
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, 200...299 ~= httpResponse.statusCode else {
            print("[ERROR] HTTP request failed: \(response)")
            throw NSError(domain: "AIManager", code: 3, userInfo: [NSLocalizedDescriptionKey: "HTTP request failed"])
        }
        
        if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
           let choices = json["choices"] as? [[String: Any]],
           let firstChoice = choices.first,
           let message = firstChoice["message"] as? [String: Any],
           let content = message["content"] as? String {
            return content
        } else {
            print("[ERROR] Failed to parse summarization response. Raw data: \(String(data: data, encoding: .utf8) ?? "Unable to convert data to string")")
            throw NSError(domain: "AIManager", code: 4, userInfo: [NSLocalizedDescriptionKey: "Unable to parse summarization response"])
        }
    }
    
    private func loadImage(fileName: String) -> UIImage? {
        if let image = UIImage(named: fileName) {
            return image
        }
        
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        if let imagePath = documentsDirectory?.appendingPathComponent(fileName),
           let image = UIImage(contentsOfFile: imagePath.path) {
            return image
        }
        
        print("[ERROR] Failed to load image: \(fileName)")
        return nil
    }
    
    func transcribeAudio(url: URL) async throws -> String {
        let audioData = try Data(contentsOf: url)
        
        let boundary = UUID().uuidString
        var request = URLRequest(url: apiBaseURL.appendingPathComponent("transcribe"))
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        // Add model field
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"model\"\r\n\r\n".data(using: .utf8)!)
        body.append("whisper-1\r\n".data(using: .utf8)!)
        
        // Add file field
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"audio.m4a\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: audio/m4a\r\n\r\n".data(using: .utf8)!)
        body.append(audioData)
        body.append("\r\n".data(using: .utf8)!)
        
        // Add closing boundary
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, 200...299 ~= httpResponse.statusCode else {
            print("[ERROR] HTTP request failed: \(response)")
            throw NSError(domain: "AIManager", code: 0, userInfo: [NSLocalizedDescriptionKey: "Server error"])
        }
        
        if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
           let transcription = json["text"] as? String {
            return transcription
        } else {
            print("[ERROR] Failed to parse transcription response. Raw data: \(String(data: data, encoding: .utf8) ?? "Unable to convert data to string")")
            throw NSError(domain: "AIManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to parse transcription response"])
        }
    }
    
    @MainActor
    func organizeAndPlanNotes(_ notes: [NoteItem]) async throws -> [NoteItem] {
        var messages: [[String: Any]] = [
            [
                "role": "system",
                "content": """
                You are an intelligent assistant designed to analyze and organize notes. Please reorganize the notes according to the following JSON format:

                [
                    {
                        "content": "First note or task"
                    },
                    {
                        "content": "Second note or task"
                    }
                ]

                Key Requirements:
                1. Response must follow the exact JSON format above
                2. Maintain the original language of the notes
                3. Integrate image descriptions into relevant notes
                4. Integrate audio transcriptions into relevant notes
                5. Each note should be concise and actionable
                6. Return an empty array [] if unable to process notes

                Example response:
                [{"content":"Complete math homework"},{"content":"Prepare for English exam"}]
                """
            ]
        ]
        
        for note in notes {
            switch note.type {
            case .text(let content):
                messages.append(["role": "user", "content": content])
            case .photo(let fileName):
                if let image = loadImage(fileName: fileName),
                   let description = try await analyzeImage(image) {
                    messages.append(["role": "user", "content": "Image content: \(description)"])
                }
            case .audio(_, _):
                if let transcription = note.transcription {
                    messages.append(["role": "user", "content": "Audio content: \(transcription)"])
                }
            }
        }
        
        messages.append(["role": "user", "content": "Please analyze these notes, summarize them, and create a simple list of tasks or points. Respond only in the specified JSON format."])
        
        let organizedContent = try await sendOrganizationRequest(messages: messages)
        let organizedNotes = convertJSONToNoteItems(organizedContent)
        
        if organizedNotes.isEmpty {
            throw NSError(domain: "AIManager", code: 5, userInfo: [NSLocalizedDescriptionKey: "Unable to process note content"])
        }
        
        return organizedNotes
    }
    
    private func sendOrganizationRequest(messages: [[String: Any]]) async throws -> String {
        var request = URLRequest(url: apiBaseURL.appendingPathComponent("chat"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody: [String: Any] = [
            "messages": messages,
            "max_tokens": 1000
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        print("[INFO] Sending request to API")
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, 200...299 ~= httpResponse.statusCode else {
            print("[ERROR] HTTP request failed: \(response)")
            if let responseString = String(data: data, encoding: .utf8) {
                print("[DEBUG] Response data: \(responseString)")
            }
            throw NSError(domain: "AIManager", code: 3, userInfo: [NSLocalizedDescriptionKey: "HTTP request failed"])
        }
        
        print("[INFO] Received API response")
        if let responseString = String(data: data, encoding: .utf8) {
            print("[DEBUG] Raw response: \(responseString)")
        }
        
        if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
           let choices = json["choices"] as? [[String: Any]],
           let firstChoice = choices.first,
           let message = firstChoice["message"] as? [String: Any],
           let content = message["content"] as? String {
            print("[INFO] Successfully parsed content")
            return content
        } else {
            print("[ERROR] Failed to parse organization response")
            if let responseString = String(data: data, encoding: .utf8) {
                print("[DEBUG] Raw data: \(responseString)")
            }
            throw NSError(domain: "AIManager", code: 4, userInfo: [NSLocalizedDescriptionKey: "Unable to parse API response"])
        }
    }
    
    private func convertJSONToNoteItems(_ jsonString: String) -> [NoteItem] {
        print("[INFO] Converting response to note items")
        let cleanedString = jsonString
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
        
        do {
            let decoder = JSONDecoder()
            let notes = try decoder.decode([OrganizedNote].self, from: cleanedString.data(using: .utf8)!)
            print("[INFO] Successfully converted \(notes.count) notes")
            return notes.map { NoteItem(type: .text($0.content)) }
        } catch {
            print("[ERROR] JSON decoding failed: \(error)")
            print("[DEBUG] Cleaned string: \(cleanedString)")
            return []
        }
    }
}

struct OrganizedNote: Codable {
    let content: String
}

private func compressImage(_ image: UIImage, maxSizeKB: Int = 1000) -> Data? {
    var compression: CGFloat = 1.0
    let maxCompression: CGFloat = 0.1
    var imageData = image.jpegData(compressionQuality: compression)
    
    while (imageData?.count ?? 0) > maxSizeKB * 1024 && compression > maxCompression {
        compression -= 0.1
        imageData = image.jpegData(compressionQuality: compression)
    }
    
    return imageData
}
