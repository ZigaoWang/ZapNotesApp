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
                You are an intelligent assistant that helps organize and structure notes. Your task is to analyze the provided notes and create a well-organized list of concise, actionable items.

                IMPORTANT: You must respond with a valid JSON array of objects, each with a "content" field. Example:
                [
                    {"content": "First organized note or task"},
                    {"content": "Second organized note or task"}
                ]

                Follow these guidelines:
                1. Preserve the original meaning and intent of the notes
                2. Keep the original language (English, Chinese, etc.)
                3. Combine related information from different notes
                4. Organize items in a logical sequence
                5. Make each note clear, specific and actionable
                6. Include ALL important information from the original notes
                7. Do NOT return an empty array unless there is absolutely no content

                Remember to ONLY output valid JSON in the exact format shown above.
                """
            ]
        ]
        
        // Debug: Print number of notes being processed
        print("[DEBUG] Processing \(notes.count) notes for organization")
        
        var noteContent = ""
        
        // First, collect all note content into a single string for better context
        for (index, note) in notes.enumerated() {
            switch note.type {
            case .text(let content):
                noteContent += "Note \(index+1) (Text): \(content)\n\n"
            case .photo(let fileName):
                if let image = loadImage(fileName: fileName),
                   let description = try await analyzeImage(image) {
                    noteContent += "Note \(index+1) (Image): \(description)\n\n"
                }
            case .audio(_, _):
                if let transcription = note.transcription {
                    noteContent += "Note \(index+1) (Audio): \(transcription)\n\n"
                }
            }
        }
        
        // Only add content if we have something meaningful
        if !noteContent.isEmpty {
            messages.append(["role": "user", "content": noteContent])
            messages.append([
                "role": "user", 
                "content": "Please organize the above notes into a structured list. Format your response as a JSON array of objects with 'content' fields. Each item should be clear and actionable."
            ])
        } else {
            // If no content, throw an error
            print("[ERROR] No content found in notes to organize")
            throw NSError(domain: "AIManager", code: 6, userInfo: [NSLocalizedDescriptionKey: "No content found in notes to organize"])
        }
        
        // Debug: Print final message structure (without full content)
        print("[DEBUG] Sending \(messages.count) messages to API")
        
        let organizedContent = try await sendOrganizationRequest(messages: messages)
        let organizedNotes = convertJSONToNoteItems(organizedContent)
        
        if organizedNotes.isEmpty {
            print("[ERROR] Received empty response or failed to parse response")
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
            "max_tokens": 1000,
            "model": "gpt-4o-mini" // Explicitly specify model to ensure consistency
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        print("[INFO] Sending request to API")
        print("[DEBUG] Request URL: \(request.url?.absoluteString ?? "unknown")")
        
        // Start tracking time for performance measurement
        let startTime = Date()
        let (data, response) = try await URLSession.shared.data(for: request)
        let responseTime = Date().timeIntervalSince(startTime)
        
        print("[DEBUG] API response time: \(String(format: "%.2f", responseTime)) seconds")
        
        guard let httpResponse = response as? HTTPURLResponse else {
            print("[ERROR] Response is not HTTPURLResponse")
            throw NSError(domain: "AIManager", code: 2, userInfo: [NSLocalizedDescriptionKey: "Invalid response type"])
        }
        
        print("[DEBUG] Response status code: \(httpResponse.statusCode)")
        
        guard 200...299 ~= httpResponse.statusCode else {
            print("[ERROR] HTTP request failed with status code: \(httpResponse.statusCode)")
            if let responseString = String(data: data, encoding: .utf8) {
                print("[DEBUG] Error response data: \(responseString)")
            }
            throw NSError(domain: "AIManager", code: 3, userInfo: [
                NSLocalizedDescriptionKey: "HTTP request failed with status \(httpResponse.statusCode)"
            ])
        }
        
        print("[INFO] Received API response")
        let responseString = String(data: data, encoding: .utf8) ?? "Unable to decode response"
        print("[DEBUG] Raw response: \(responseString)")
        
        // Validate that we received a non-empty response
        guard !responseString.isEmpty else {
            print("[ERROR] Received empty response from API")
            throw NSError(domain: "AIManager", code: 7, userInfo: [NSLocalizedDescriptionKey: "Empty response from API"])
        }
        
        do {
            guard let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
                print("[ERROR] Response is not a valid JSON object")
                throw NSError(domain: "AIManager", code: 4, userInfo: [NSLocalizedDescriptionKey: "Invalid JSON response"])
            }
            
            guard let choices = json["choices"] as? [[String: Any]], !choices.isEmpty else {
                print("[ERROR] No choices found in response")
                throw NSError(domain: "AIManager", code: 4, userInfo: [NSLocalizedDescriptionKey: "No choices in response"])
            }
            
            guard let firstChoice = choices.first,
                  let message = firstChoice["message"] as? [String: Any],
                  let content = message["content"] as? String else {
                print("[ERROR] Could not extract content from response")
                throw NSError(domain: "AIManager", code: 4, userInfo: [NSLocalizedDescriptionKey: "Unable to extract content"])
            }
            
            print("[INFO] Successfully parsed content")
            return content
        } catch {
            print("[ERROR] Failed to parse organization response: \(error.localizedDescription)")
            throw NSError(domain: "AIManager", code: 4, userInfo: [NSLocalizedDescriptionKey: "Unable to parse API response: \(error.localizedDescription)"])
        }
    }
    
    private func convertJSONToNoteItems(_ jsonString: String) -> [NoteItem] {
        print("[INFO] Converting response to note items")
        
        // Attempt to extract JSON data if it's wrapped in markdown code blocks or has other text
        var cleanedString = jsonString.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Try to find JSON array pattern
        if let jsonStart = cleanedString.range(of: "\\[\\s*{", options: .regularExpression),
           let jsonEnd = cleanedString.range(of: "}\\s*\\]", options: .regularExpression, range: jsonStart.upperBound..<cleanedString.endIndex) {
            
            let startIndex = jsonStart.lowerBound
            let endIndex = jsonEnd.upperBound
            cleanedString = String(cleanedString[startIndex..<endIndex])
            print("[DEBUG] Extracted JSON array: \(cleanedString)")
        } else {
            // If we can't find pattern, just clean up markdown and try with whole string
            cleanedString = cleanedString
                .replacingOccurrences(of: "```json", with: "")
                .replacingOccurrences(of: "```", with: "")
        }
        
        // Try multiple approaches to decode the JSON
        var organizedNotes: [OrganizedNote] = []
        
        // First attempt - try directly as an array
        do {
            let decoder = JSONDecoder()
            organizedNotes = try decoder.decode([OrganizedNote].self, from: cleanedString.data(using: .utf8)!)
            print("[INFO] Successfully parsed JSON array directly")
        } catch {
            print("[DEBUG] First parsing attempt failed: \(error.localizedDescription)")
            
            // Second attempt - try to parse as if the content is embedded in another object
            if cleanedString.contains("\"content\"") {
                do {
                    // Try to extract just the content field values and create an array manually
                    let pattern = "\"content\"\\s*:\\s*\"([^\"]*)\"" 
                    let regex = try NSRegularExpression(pattern: pattern)
                    let nsString = cleanedString as NSString
                    let matches = regex.matches(in: cleanedString, range: NSRange(location: 0, length: nsString.length))
                    
                    organizedNotes = matches.compactMap { match -> OrganizedNote? in
                        if match.numberOfRanges > 1 {
                            let contentRange = match.range(at: 1)
                            let content = nsString.substring(with: contentRange)
                            return OrganizedNote(content: content)
                        }
                        return nil
                    }
                    
                    if !organizedNotes.isEmpty {
                        print("[INFO] Successfully extracted \(organizedNotes.count) notes using regex")
                    }
                } catch {
                    print("[DEBUG] Regex extraction failed: \(error.localizedDescription)")
                }
            }
            
            // If both attempts failed and we have something that might be plain text
            if organizedNotes.isEmpty && !cleanedString.isEmpty {
                // Final fallback - treat as plain text notes separated by line breaks
                let lines = cleanedString
                    .components(separatedBy: .newlines)
                    .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
                
                if !lines.isEmpty {
                    print("[INFO] Treating response as plain text with \(lines.count) lines")
                    organizedNotes = lines.map { OrganizedNote(content: $0) }
                }
            }
        }
        
        print("[INFO] Successfully converted \(organizedNotes.count) notes")
        return organizedNotes.map { NoteItem(type: .text($0.content)) }
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
