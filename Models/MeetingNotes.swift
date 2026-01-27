//
//  MeetingNotes.swift
//  ZoomAutoJoiner
//
//  Created by Trilokeshwar Jaikumar on 11/20/25.
//

import Foundation

struct MeetingNotes: Codable, Equatable, Hashable {
    var summary: String
    var keyTakeaways: [String]
    var actionItems: [ActionItem]
    var fullTranscript: String?
    var generatedAt: Date
    var model: String
    
    init(
        summary: String,
        keyTakeaways: [String],
        actionItems: [ActionItem],
        fullTranscript: String? = nil,
        model: String = "gpt-4"
    ) {
        self.summary = summary
        self.keyTakeaways = keyTakeaways
        self.actionItems = actionItems
        self.fullTranscript = fullTranscript
        self.generatedAt = Date()
        self.model = model
    }
}

struct ActionItem: Identifiable, Codable, Equatable, Hashable {
    var id: UUID
    var task: String
    var assignee: String?
    var dueDate: Date?
    var completed: Bool
    
    init(
        id: UUID = UUID(),
        task: String,
        assignee: String? = nil,
        dueDate: Date? = nil,
        completed: Bool = false
    ) {
        self.id = id
        self.task = task
        self.assignee = assignee
        self.dueDate = dueDate
        self.completed = completed
    }
}
