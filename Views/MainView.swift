//
//  MainView.swift
//  ZoomAutoJoiner
//
//  Created by Trilokeshwar Jaikumar on 11/21/25.
//

import SwiftUI

struct MainView: View {
    @EnvironmentObject var meetingListViewModel: MeetingListViewModel
    @EnvironmentObject var settingsViewModel: SettingsViewModel
    @State private var selectedMeetingId: UUID?
    
    var body: some View {
        NavigationSplitView {
            MeetingListView(selectedMeetingId: $selectedMeetingId)
                .frame(minWidth: 300)
        } detail: {
            if let meetingId = selectedMeetingId,
               let meeting = meetingListViewModel.meetings.first(where: { $0.id == meetingId }) {
                MeetingDetailView(meetingId: meeting.id)
                    .id(meeting.id)
            } else {
                EmptyStateView()
            }
        }
        .onAppear {
            scheduleUpcomingMeetings()
        }
    }
    
    private func scheduleUpcomingMeetings() {
        for meeting in meetingListViewModel.upcomingMeetings {
            if meeting.status == .notStarted {
                // Schedule auto-join
                meetingListViewModel.scheduleAutoJoin(
                    for: meeting,
                    settings: settingsViewModel.settings
                )
            } else if meeting.status == .inProgress {
                // If app was restarted during meeting, schedule auto-end
                meetingListViewModel.scheduleAutoEnd(for: meeting)
            }
        }
    }
}

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("No Meeting Selected")
                .font(.title2)
                .foregroundColor(.secondary)
            
            Text("Select a meeting from the list to view details")
                .font(.body)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
