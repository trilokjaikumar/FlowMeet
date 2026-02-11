//
//  LiveAssistantService.swift
//  ZoomAutoJoiner
//
//  Created by Trilokeshwar Jaikumar on 11/22/25.
//

import Foundation
import Combine

class LiveAssistantService: ObservableObject {
    static let shared = LiveAssistantService()
    
    @Published var isActive = false
    @Published var currentSession: LiveAssistantSession?
    
    let audioService = LiveAudioCaptureService()
    let screenService = ScreenCaptureService()
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        setupObservers()
    }
    
    private func setupObservers() {
        // Observe audio transcript updates
        audioService.$accumulatedTranscript
            .sink { [weak self] transcript in
                self?.currentSession?.audioTranscript = transcript
            }
            .store(in: &cancellables)
        
        // Observe screen text updates
        screenService.$latestScreenText
            .sink { [weak self] text in
                self?.currentSession?.screenText = text
            }
            .store(in: &cancellables)
    }
    
    func start(captureScreen: Bool, captureAudio: Bool) async -> Bool {
        guard !isActive else { return false }
        
        print("🚀 Starting Live Assistant...")
        print("   Capture Audio: \(captureAudio)")
        print("   Capture Screen: \(captureScreen)")
        
        currentSession = LiveAssistantSession()
        
        var success = true
        
        if captureAudio {
            success = await audioService.startListening()
        }
        
        if captureScreen && success {
            screenService.startCapturing()
        }
        
        if success {
            await MainActor.run {
                self.isActive = true
            }
            print("✅ Live Assistant started successfully")
        }
        
        return success
    }
    
    func stop() -> LiveAssistantSession? {
        audioService.stopListening()
        screenService.stopCapturing()
        isActive = false
        
        currentSession?.endTime = Date()
        let session = currentSession
        currentSession = nil
        
        print("🛑 Live Assistant stopped")
        return session
    }
    
    func askQuestion(_ question: String, apiKey: String) async throws -> String {
        guard currentSession != nil else {
            throw NSError(domain: "LiveAssistant", code: -1, userInfo: [NSLocalizedDescriptionKey: "No active session"])
        }

        // Add user message directly to the live session
        let userMessage = LiveAssistantMessage(role: .user, content: question)
        currentSession?.conversationHistory.append(userMessage)

        // Build context from current session state
        let systemPrompt = buildSystemPrompt(for: currentSession!)

        // Call OpenAI (concurrent transcript/screen updates won't be overwritten)
        let response = try await queryOpenAI(systemPrompt: systemPrompt, userQuestion: question, apiKey: apiKey)

        // Add assistant response directly to the live session
        let assistantMessage = LiveAssistantMessage(role: .assistant, content: response)
        currentSession?.conversationHistory.append(assistantMessage)

        return response
    }
    
    private func buildSystemPrompt(for session: LiveAssistantSession) -> String {
        var prompt = """
        You are an intelligent live assistant helping someone in real-time. You have access to:
        1. Real-time audio transcript of what's being said around them
        2. Text visible on their screen (OCR)
        3. Previous conversation history
        
        Your job is to:
        - Answer questions about what's happening
        - Provide relevant information and context
        - Suggest talking points or responses
        - Help with note-taking and summarization
        - Be concise, helpful, and actionable
        
        Context you're helping with: This could be a meeting, lecture, presentation, or any situation where the user needs real-time assistance.
        
        """
        
        if !session.audioTranscript.isEmpty {
            let recentTranscript = String(session.audioTranscript.suffix(2000))
            prompt += "\n**Recent Audio Transcript:**\n\(recentTranscript)\n"
        }
        
        if !session.screenText.isEmpty {
            let recentScreen = String(session.screenText.suffix(1000))
            prompt += "\n**Visible Screen Text:**\n\(recentScreen)\n"
        }
        
        return prompt
    }
    
    private func queryOpenAI(systemPrompt: String, userQuestion: String, apiKey: String) async throws -> String {
        let url = URL(string: "https://api.openai.com/v1/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        var messages: [[String: String]] = [
            ["role": "system", "content": systemPrompt]
        ]
        
        // Add recent conversation history (last 5 messages)
        if let session = currentSession {
            let recentHistory = session.conversationHistory.suffix(5)
            for msg in recentHistory {
                messages.append([
                    "role": msg.role == .user ? "user" : "assistant",
                    "content": msg.content
                ])
            }
        }
        
        // Add current question
        messages.append(["role": "user", "content": userQuestion])
        
        let requestBody: [String: Any] = [
            "model": "gpt-4-turbo-preview",
            "messages": messages,
            "temperature": 0.7,
            "max_tokens": 500
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw NSError(domain: "LiveAssistant", code: -1, userInfo: [NSLocalizedDescriptionKey: "API request failed"])
        }
        
        let result = try JSONDecoder().decode(ChatCompletionResponse.self, from: data)
        guard let content = result.choices.first?.message.content else {
            throw NSError(domain: "LiveAssistant", code: -1, userInfo: [NSLocalizedDescriptionKey: "No response from AI"])
        }
        
        return content
    }
    
    func saveSession(_ session: LiveAssistantSession) {
        // Save to disk for later review
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        
        guard let data = try? encoder.encode(session) else { return }
        
        let documentsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let sessionsDir = documentsDir.appendingPathComponent("assistant-sessions")
        
        try? FileManager.default.createDirectory(at: sessionsDir, withIntermediateDirectories: true)
        
        let filename = "\(session.id.uuidString).json"
        let fileURL = sessionsDir.appendingPathComponent(filename)
        
        try? data.write(to: fileURL)
        print("💾 Session saved: \(fileURL.path)")
    }
}
