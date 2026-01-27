//
//  LiveAssistantViewModel.swift
//  ZoomAutoJoiner
//
//  Created by Trilokeshwar Jaikumar on 11/22/25.
//

import Foundation
import Combine

@MainActor
class LiveAssistantViewModel: ObservableObject {
    @Published var isActive = false
    @Published var messages: [LiveAssistantMessage] = []
    @Published var currentInput = ""
    @Published var isProcessing = false
    @Published var errorMessage: String?
    
    @Published var captureAudio = true
    @Published var captureScreen = false
    @Published var showTranscript = false
    @Published var liveTranscript = ""
    
    private let service = LiveAssistantService.shared
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        service.$currentSession
            .sink { [weak self] session in
                self?.messages = session?.conversationHistory ?? []
            }
            .store(in: &cancellables)
        
        service.$isActive
            .sink { [weak self] active in
                self?.isActive = active
            }
            .store(in: &cancellables)
        
        service.audioService.$latestTranscript
            .sink { [weak self] transcript in
                self?.liveTranscript = transcript
            }
            .store(in: &cancellables)
    }
    
    func start() async {
        let success = await service.start(
            captureScreen: captureScreen,
            captureAudio: captureAudio
        )
        
        if success {
            // Add welcome message
            let welcome = LiveAssistantMessage(
                role: .system,
                content: "🎧 Live Assistant started. Ask me anything!"
            )
            messages.append(welcome)
        } else {
            errorMessage = "Failed to start. Please grant microphone and speech recognition permissions in System Settings."
        }
    }
    
    func stop() {
        if let session = service.stop() {
            // Optionally save session
            showSavePrompt(for: session)
        }
    }
    
    func sendMessage() async {
        guard !currentInput.isEmpty, !isProcessing else { return }
        
        let question = currentInput
        currentInput = ""
        isProcessing = true
        errorMessage = nil
        
        // Get API key
        guard let apiKey = KeychainManager.shared.load(key: "openai_api_key") else {
            errorMessage = "OpenAI API key not found. Add it in Settings."
            isProcessing = false
            return
        }
        
        do {
            let response = try await service.askQuestion(question, apiKey: apiKey)
            print("💬 AI Response: \(response)")
        } catch {
            errorMessage = "Failed to get response: \(error.localizedDescription)"
        }
        
        isProcessing = false
    }
    
    private func showSavePrompt(for session: LiveAssistantSession) {
        // User can optionally save the session
        if !session.conversationHistory.isEmpty {
            service.saveSession(session)
        }
    }
}
