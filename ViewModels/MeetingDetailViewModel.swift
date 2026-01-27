//
//  MeetingDetailViewModel.swift
//  ZoomAutoJoiner
//
//  Created by Trilokeshwar Jaikumar on 11/21/25.
//

import Foundation
import AppKit
import Combine
import UniformTypeIdentifiers

@MainActor
class MeetingDetailViewModel: ObservableObject {
    @Published var meeting: Meeting
    
    init(meeting: Meeting) {
        self.meeting = meeting
    }
    
    func copyToClipboard(_ text: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
    }
    
    func exportAsMarkdown() -> String {
        guard let notes = meeting.notes else { return "" }
        
        var markdown = """
        # \(meeting.title)
        
        **Date:** \(meeting.startDate.formattedDateTime())
        **Mode:** \(meeting.mode.rawValue)
        **Source:** \(meeting.source.rawValue)
        
        ---
        
        ## Summary
        
        \(notes.summary)
        
        ## Key Takeaways
        
        """
        
        for (index, takeaway) in notes.keyTakeaways.enumerated() {
            markdown += "\(index + 1). \(takeaway)\n"
        }
        
        markdown += "\n## Action Items\n\n"
        
        for item in notes.actionItems {
            let assignee = item.assignee.map { " (@\($0))" } ?? ""
            let status = item.completed ? "[x]" : "[ ]"
            markdown += "- \(status) \(item.task)\(assignee)\n"
        }
        
        if let transcript = notes.fullTranscript {
            markdown += """
            
            ---
            
            ## Full Transcript
            
            \(transcript)
            """
        }
        
        return markdown
    }
    
    func saveMarkdownToFile() {
        let markdown = exportAsMarkdown()
        let panel = NSSavePanel()
        panel.allowedContentTypes = [UTType.plainText]
        panel.nameFieldStringValue = "\(meeting.title).md"
        
        panel.begin { response in
            if response == .OK, let url = panel.url {
                try? markdown.write(to: url, atomically: true, encoding: .utf8)
            }
        }
    }
    
    func toggleActionItem(_ item: ActionItem) {
        guard var notes = meeting.notes else { return }
        
        if let index = notes.actionItems.firstIndex(where: { $0.id == item.id }) {
            notes.actionItems[index].completed.toggle()
            meeting.notes = notes
        }
    }
}
