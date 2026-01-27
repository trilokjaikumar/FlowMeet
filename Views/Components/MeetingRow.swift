//
//  MeetingRow.swift
//  ZoomAutoJoiner
//
//  Created by Trilokeshwar Jaikumar on 11/21/25.
//

import SwiftUI

struct MeetingRow: View {
    let meeting: Meeting
    
    var body: some View {
        HStack(spacing: 12) {
            // Time indicator
            VStack(alignment: .center, spacing: 2) {
                Text(meeting.startDate.formattedTime())
                    .font(.caption)
                    .bold()
                
                if meeting.startDate.isToday() {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 6, height: 6)
                }
            }
            .frame(width: 60)
            
            Divider()
            
            // Meeting info
            VStack(alignment: .leading, spacing: 4) {
                Text(meeting.title)
                    .font(.body)
                    .lineLimit(1)
                
                HStack(spacing: 8) {
                    SourceBadge(source: meeting.source)
                    ModeBadge(mode: meeting.mode)
                    NotesStatusIndicator(status: meeting.status)
                }
            }
            
            Spacer()
            
            // Status icon
            if meeting.isInProgress {
                Image(systemName: "waveform.circle.fill")
                    .foregroundColor(.blue)
                    .imageScale(.large)
            }
        }
        .padding(.vertical, 4)
    }
}
