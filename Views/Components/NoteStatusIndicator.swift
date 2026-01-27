//
//  NoteStatusIndicator.swift
//  ZoomAutoJoiner
//
//  Created by Trilokeshwar Jaikumar on 11/21/25.
//

import SwiftUI

struct NotesStatusIndicator: View {
    let status: MeetingStatus
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(statusColor)
                .frame(width: 6, height: 6)
            
            Text(status.rawValue)
        }
        .font(.caption)
        .foregroundColor(.secondary)
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
}
