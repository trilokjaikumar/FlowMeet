//
//  LiveAssistantMessage.swift
//  ZoomAutoJoiner
//
//  Created by Trilokeshwar Jaikumar on 11/22/25.
//

import Foundation

struct LiveAssistantMessage: Identifiable, Codable, Equatable {
    var id: UUID
    var role: MessageRole
    var content: String
    var timestamp: Date
    
    init(id: UUID = UUID(), role: MessageRole, content: String, timestamp: Date = Date()) {
        self.id = id
        self.role = role
        self.content = content
        self.timestamp = timestamp
    }
    
    enum MessageRole: String, Codable {
        case user = "User"
        case assistant = "Assistant"
        case system = "System"
    }
}

struct LiveAssistantSession: Codable {
    var id: UUID
    var audioTranscript: String
    var screenText: String
    var conversationHistory: [LiveAssistantMessage]
    var sessionTitle: String
    var startTime: Date
    var endTime: Date?
    
    init(sessionTitle: String = "Untitled Session") {
        self.id = UUID()
        self.audioTranscript = ""
        self.screenText = ""
        self.conversationHistory = []
        self.sessionTitle = sessionTitle
        self.startTime = Date()
        self.endTime = nil
    }
}
