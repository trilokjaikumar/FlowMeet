//
//  MeetingListView.swift
//  ZoomAutoJoiner
//
//  Created by Trilokeshwar Jaikumar on 11/21/25.
//

import SwiftUI

struct MeetingListView: View {
    @EnvironmentObject var viewModel: MeetingListViewModel
    @EnvironmentObject var settingsViewModel: SettingsViewModel
    @Binding var selectedMeetingId: UUID?
    @State private var showingManualMeeting = false
    @State private var searchText = ""
    @State private var selectedTab = 0 // 0 = Upcoming, 1 = Past
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Meetings")
                    .font(.title2)
                    .bold()
                
                Spacer()
                
                Button(action: { showingManualMeeting = true }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                }
                .buttonStyle(.plain)
                
                Button(action: syncCalendars) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.title3)
                }
                .buttonStyle(.plain)
                .disabled(viewModel.isLoading)
            }
            .padding()
            
            Divider()
            
            // Search
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search meetings", text: $searchText)
                    .textFieldStyle(.plain)
            }
            .padding(8)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
            .padding(.horizontal)
            .padding(.top, 8)
            
            // Tab Selector
            Picker("", selection: $selectedTab) {
                Text("Upcoming (\(filteredUpcomingMeetings.count))").tag(0)
                Text("Past (\(filteredPastMeetings.count + filteredMeetingsWithNotes.count))").tag(1)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.top, 8)
            
            // Meeting List
            if selectedTab == 0 {
                // Upcoming Tab
                List(selection: $selectedMeetingId) {
                    if filteredUpcomingMeetings.isEmpty {
                        Text("No upcoming meetings")
                            .foregroundColor(.secondary)
                            .padding()
                    } else {
                        ForEach(filteredUpcomingMeetings, id: \.id) { meeting in
                            MeetingRow(meeting: meeting)
                                .tag(meeting.id)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    selectedMeetingId = meeting.id
                                }
                                .contextMenu {
                                    Button("Join Now") {
                                        _ = ZoomService.shared.joinMeeting(meeting)
                                    }
                                    Button("Delete") {
                                        viewModel.deleteMeeting(meeting)
                                        if selectedMeetingId == meeting.id {
                                            selectedMeetingId = nil
                                        }
                                    }
                                }
                        }
                    }
                }
                .listStyle(.sidebar)
            } else {
                // Past Tab
                List(selection: $selectedMeetingId) {
                    if !filteredMeetingsWithNotes.isEmpty {
                        Section("Completed with Notes") {
                            ForEach(filteredMeetingsWithNotes, id: \.id) { meeting in
                                MeetingRow(meeting: meeting)
                                    .tag(meeting.id)
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        selectedMeetingId = meeting.id
                                    }
                                    .contextMenu {
                                        Button("Delete") {
                                            viewModel.deleteMeeting(meeting)
                                            if selectedMeetingId == meeting.id {
                                                selectedMeetingId = nil
                                            }
                                        }
                                    }
                            }
                        }
                    }
                    
                    if !filteredPastMeetings.isEmpty {
                        Section("Past Meetings") {
                            ForEach(filteredPastMeetings, id: \.id) { meeting in
                                MeetingRow(meeting: meeting)
                                    .tag(meeting.id)
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        selectedMeetingId = meeting.id
                                    }
                                    .contextMenu {
                                        Button("Delete") {
                                            viewModel.deleteMeeting(meeting)
                                            if selectedMeetingId == meeting.id {
                                                selectedMeetingId = nil
                                            }
                                        }
                                    }
                            }
                        }
                    }
                    
                    if filteredMeetingsWithNotes.isEmpty && filteredPastMeetings.isEmpty {
                        Text("No past meetings")
                            .foregroundColor(.secondary)
                            .padding()
                    }
                }
                .listStyle(.sidebar)
            }
        }
        .sheet(isPresented: $showingManualMeeting) {
            ManualMeetingView { meeting in
                viewModel.addMeeting(meeting)
                viewModel.scheduleAutoJoin(for: meeting, settings: settingsViewModel.settings)
            }
        }
    }
    
    private var filteredUpcomingMeetings: [Meeting] {
        filterMeetings(viewModel.upcomingMeetings)
    }
    
    private var filteredMeetingsWithNotes: [Meeting] {
        let meetingsWithNotes = viewModel.pastMeetings.filter { $0.notes != nil && $0.status == .ready }
        return filterMeetings(meetingsWithNotes)
    }
    
    private var filteredPastMeetings: [Meeting] {
        let pastWithoutNotes = viewModel.pastMeetings.filter { $0.notes == nil || $0.status != .ready }
        return filterMeetings(pastWithoutNotes)
    }
    
    private func filterMeetings(_ meetings: [Meeting]) -> [Meeting] {
        if searchText.isEmpty {
            return meetings
        }
        return meetings.filter { meeting in
            meeting.title.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    private func syncCalendars() {
        Task {
            await viewModel.syncCalendars(settings: settingsViewModel.settings)
        }
    }
}
