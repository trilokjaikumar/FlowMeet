//
//  OpenAIService.swift
//  ZoomAutoJoiner
//
//  Created by Trilokeshwar Jaikumar on 11/21/25.
//

import Foundation

class OpenAIService {
    static let shared = OpenAIService()
    
    private let baseURL = "https://api.openai.com/v1"
    
    func transcribeAudio(fileURL: URL, apiKey: String, model: String = "whisper-1") async throws -> String {
        let url = URL(string: "\(baseURL)/audio/transcriptions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        // Add file
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"audio.m4a\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: audio/m4a\r\n\r\n".data(using: .utf8)!)
        body.append(try Data(contentsOf: fileURL))
        body.append("\r\n".data(using: .utf8)!)
        
        // Add model
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"model\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(model)\r\n".data(using: .utf8)!)
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw OpenAIError.apiError("Transcription failed")
        }
        
        let result = try JSONDecoder().decode(TranscriptionResponse.self, from: data)
        return result.text
    }
    
    func generateNotes(transcript: String, apiKey: String, model: String = "gpt-4-turbo-preview") async throws -> MeetingNotes {
        let url = URL(string: "\(baseURL)/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let prompt = """
        You are an AI meeting assistant. Given the meeting transcript below, generate:
        
        1. A short summary (3-5 sentences)
        2. 5 bullet-point key takeaways
        3. A list of action items with assignees if mentioned
        
        Return ONLY a valid JSON object with this structure:
        {
          "summary": "...",
          "keyTakeaways": ["...", "...", ...],
          "actionItems": [{"task": "...", "assignee": "...", "dueDate": null}, ...]
        }
        
        Transcript:
        \(transcript)
        """
        
        let requestBody: [String: Any] = [
            "model": model,
            "messages": [
                ["role": "system", "content": "You are a helpful meeting assistant that generates structured notes."],
                ["role": "user", "content": prompt]
            ],
            "temperature": 0.7,
            "response_format": ["type": "json_object"]
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw OpenAIError.apiError("Notes generation failed")
        }
        
        let result = try JSONDecoder().decode(ChatCompletionResponse.self, from: data)
        guard let content = result.choices.first?.message.content else {
            throw OpenAIError.parsingError
        }
        
        let notesData = try JSONDecoder().decode(NotesJSON.self, from: content.data(using: .utf8)!)
        
        let actionItems = notesData.actionItems.map { item in
            ActionItem(
                task: item.task,
                assignee: item.assignee,
                dueDate: nil
            )
        }
        
        return MeetingNotes(
            summary: notesData.summary,
            keyTakeaways: notesData.keyTakeaways,
            actionItems: actionItems,
            fullTranscript: transcript,
            model: model
        )
    }
}

// MARK: - Response Types

struct TranscriptionResponse: Codable {
    let text: String
}

struct ChatCompletionResponse: Codable {
    let choices: [Choice]
    
    struct Choice: Codable {
        let message: Message
    }
    
    struct Message: Codable {
        let content: String
    }
}

struct NotesJSON: Codable {
    let summary: String
    let keyTakeaways: [String]
    let actionItems: [ActionItemJSON]
}

struct ActionItemJSON: Codable {
    let task: String
    let assignee: String?
    let dueDate: String?
}

enum OpenAIError: Error {
    case apiError(String)
    case parsingError
}
