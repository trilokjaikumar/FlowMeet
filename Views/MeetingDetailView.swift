//
//  MeetingDetailView.swift
//  ZoomAutoJoiner
//
//  Created by Trilokeshwar Jaikumar on 11/21/25.
//

import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct MeetingDetailView: View {
    @EnvironmentObject var meetingListViewModel: MeetingListViewModel
    let meetingId: UUID
    
    @State private var selectedTab = 0
    
    private var meeting: Meeting? {
        meetingListViewModel.meetings.first(where: { $0.id == meetingId })
    }
    
    var body: some View {
        Group {
            if let meeting = meeting {
                meetingContent(for: meeting)
            } else {
                Text("Meeting not found")
                    .foregroundColor(.secondary)
            }
        }
    }
    
    @ViewBuilder
    private func meetingContent(for meeting: Meeting) -> some View {
        VStack(spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(meeting.title)
                        .font(.title)
                        .bold()
                    
                    Spacer()
                    
                    ModeBadge(mode: meeting.mode)
                    SourceBadge(source: meeting.source)
                    NotesStatusIndicator(status: meeting.status)
                }
                
                HStack {
                    Label(meeting.startDate.relativeDateString(), systemImage: "calendar")
                    Spacer()
                    
                    if meeting.isUpcoming && meeting.status == .notStarted {
                        Button("Join Now") {
                            _ = ZoomService.shared.joinMeeting(meeting)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    
                    if meeting.status == .inProgress {
                        HStack(spacing: 8) {
                            // Recording indicator
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(Color.red)
                                    .frame(width: 8, height: 8)
                                Text("Recording")
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                            
                            Button("End Meeting") {
                                Task {
                                    await meetingListViewModel.handleMeetingEnd(meeting)
                                }
                            }
                            .buttonStyle(.bordered)
                            .tint(.red)
                        }
                    }
                }
                .foregroundColor(.secondary)
            }
            .padding()
            
            Divider()
            
            // Content
            if meeting.status == .ready, let notes = meeting.notes {
                TabView(selection: $selectedTab) {
                    // Summary Tab
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            SummarySection(summary: notes.summary)
                            KeyTakeawaysSection(takeaways: notes.keyTakeaways)
                            ActionItemsSection(
                                actionItems: notes.actionItems,
                                onToggle: { item in
                                    toggleActionItem(item, in: meeting)
                                }
                            )
                        }
                        .padding()
                    }
                    .tabItem { Label("Summary", systemImage: "doc.text") }
                    .tag(0)
                    
                    // Transcript Tab
                    if let transcript = notes.fullTranscript {
                        ScrollView {
                            Text(transcript)
                                .font(.system(.body, design: .monospaced))
                                .padding()
                        }
                        .tabItem { Label("Transcript", systemImage: "text.quote") }
                        .tag(1)
                    }
                }
                
                Divider()
                
                // Action Buttons
                HStack {
                    Button("Copy Summary") {
                        copyToClipboard(notes.summary)
                    }
                    
                    Button("Export Markdown") {
                        saveMarkdownToFile(for: meeting)
                    }
                    
                    Spacer()
                }
                .padding()
                
            } else {
                StatusPlaceholder(status: meeting.status)
            }
        }
    }
    
    private func toggleActionItem(_ item: ActionItem, in meeting: Meeting) {
        guard var notes = meeting.notes else { return }
        
        if let index = notes.actionItems.firstIndex(where: { $0.id == item.id }) {
            notes.actionItems[index].completed.toggle()
            var updatedMeeting = meeting
            updatedMeeting.notes = notes
            meetingListViewModel.updateMeeting(updatedMeeting)
        }
    }
    
    private func copyToClipboard(_ text: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
    }
    
    private func saveMarkdownToFile(for meeting: Meeting) {
        guard let notes = meeting.notes else { return }
        
        let markdown = exportAsMarkdown(meeting: meeting, notes: notes)
        let panel = NSSavePanel()
        panel.allowedContentTypes = [
            UTType(filenameExtension: "md")!,
            .plainText
        ]
        panel.nameFieldStringValue = "\(meeting.title).md"
        
        panel.begin { response in
            if response == .OK, let url = panel.url {
                try? markdown.write(to: url, atomically: true, encoding: .utf8)
            }
        }
    }
    
    private func exportAsMarkdown(meeting: Meeting, notes: MeetingNotes) -> String {
        var markdown = """
        # \(meeting.title)
        
        **Date:** \(meeting.startDate.formattedDateTime())
        **Mode:** \(meeting.mode.displayName)
        **Source:** \(meeting.source.displayName)
        
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
}

// MARK: - Section Views

struct SummarySection: View {
    let summary: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Summary")
                .font(.title2)
                .bold()
            
            Text(summary)
                .font(.body)
                .foregroundColor(.primary)
        }
    }
}

struct KeyTakeawaysSection: View {
    let takeaways: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Key Takeaways")
                .font(.title2)
                .bold()
            
            ForEach(Array(takeaways.enumerated()), id: \.offset) { index, takeaway in
                HStack(alignment: .top, spacing: 8) {
                    Text("\(index + 1).")
                        .bold()
                    Text(takeaway)
                }
            }
        }
    }
}

struct ActionItemsSection: View {
    let actionItems: [ActionItem]
    let onToggle: (ActionItem) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Action Items")
                .font(.title2)
                .bold()
            
            ForEach(actionItems) { item in
                HStack(alignment: .top) {
                    Button(action: { onToggle(item) }) {
                        Image(systemName: item.completed ? "checkmark.square.fill" : "square")
                            .foregroundColor(item.completed ? .green : .gray)
                    }
                    .buttonStyle(.plain)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.task)
                            .strikethrough(item.completed)
                        
                        if let assignee = item.assignee {
                            Text("@\(assignee)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
    }
}

struct StatusPlaceholder: View {
    let status: MeetingStatus
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: statusIcon)
                .font(.system(size: 60))
                .foregroundColor(statusColor)
            
            Text(statusMessage)
                .font(.title3)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var statusIcon: String {
        switch status {
        case .notStarted:
            return "clock"
        case .inProgress:
            return "waveform.circle"
        case .processing:
            return "gearshape.2"
        case .ready:
            return "checkmark.circle"
        case .failed:
            return "exclamationmark.triangle"
        }
    }
    
    private var statusColor: Color {
        switch status {
        case .notStarted:
            return .gray
        case .inProgress:
            return .blue
        case .processing:
            return .orange
        case .ready:
            return .green
        case .failed:
            return .red
        }
    }
    
    private var statusMessage: String {
        switch status {
        case .notStarted:
            return "Meeting hasn't started yet"
        case .inProgress:
            return "Recording in progress...\nMeeting will auto-end at scheduled time"
        case .processing:
            return "Processing recording...\nTranscribing audio and generating AI notes\nThis may take a few minutes"
        case .ready:
            return "Notes ready"
        case .failed:
            return "Failed to process meeting\nCheck console for errors"
        }
    }
}
