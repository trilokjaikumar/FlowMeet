//
//  MeetingListViewModel.swift
//  FlowMeet
//
//  Updated to post notifications when meetings update
//

import Foundation
import Combine

@MainActor
class MeetingListViewModel: ObservableObject {
    @Published var meetings: [Meeting] = [] {
        didSet {
            // Post notification when meetings change (for dashboard)
            NotificationCenter.default.post(
                name: .meetingsDidUpdate,
                object: meetings
            )
        }
    }
    
    @Published var isLoading = false
    
    private let calendarService = CalendarService()
    
    var upcomingMeetings: [Meeting] {
        meetings
            .filter { $0.status == .notStarted && $0.startDate > Date() }
            .sorted { $0.startDate < $1.startDate }
    }
    
    var pastMeetings: [Meeting] {
        meetings
            .filter { $0.status != .notStarted || $0.startDate < Date() }
            .sorted { $0.startDate > $1.startDate }
    }
    
    func addMeeting(_ meeting: Meeting) {
        meetings.append(meeting)
        saveMeetings()
    }
    
    func updateMeeting(_ meeting: Meeting) {
        if let index = meetings.firstIndex(where: { $0.id == meeting.id }) {
            meetings[index] = meeting
            saveMeetings()
        }
    }
    
    func deleteMeeting(_ meeting: Meeting) {
        MeetingScheduler.shared.cancelMeeting(meeting.id)
        meetings.removeAll { $0.id == meeting.id }
        saveMeetings()
    }
    
    func syncCalendars(settings: AppSettings) async {
        isLoading = true
        
        if settings.appleCalendarEnabled {
            let calendarMeetings = await calendarService.fetchUpcomingZoomMeetings(days: settings.calendarSyncDays)
            
            // Merge with existing meetings
            for calendarMeeting in calendarMeetings {
                if !meetings.contains(where: { $0.calendarEventId == calendarMeeting.calendarEventId }) {
                    meetings.append(calendarMeeting)
                }
            }
        }
        
        saveMeetings()
        isLoading = false
        
        print("✅ Synced \(meetings.count) meetings")
    }
    
    func scheduleAutoJoin(for meeting: Meeting, settings: AppSettings) {
        MeetingScheduler.shared.scheduleMeeting(
            meeting,
            offsetMinutes: settings.joinOffsetMinutes
        ) { [weak self] joinMeeting in
            _ = ZoomService.shared.joinMeeting(joinMeeting)
            
            // Update status
            Task { @MainActor in
                if let index = self?.meetings.firstIndex(where: { $0.id == joinMeeting.id }) {
                    self?.meetings[index].status = .inProgress
                }
            }
        }
    }
    
    func scheduleAutoEnd(for meeting: Meeting) {
        let endTime = meeting.startDate.addingTimeInterval(meeting.duration)
        let timeInterval = endTime.timeIntervalSinceNow
        
        guard timeInterval > 0 else { return }
        
        Task {
            try? await Task.sleep(nanoseconds: UInt64(timeInterval * 1_000_000_000))
            await handleMeetingEnd(meeting)
        }
    }
    
    func handleMeetingEnd(_ meeting: Meeting) async {
        guard let index = meetings.firstIndex(where: { $0.id == meeting.id }) else { return }
        
        meetings[index].status = .processing
        
        // TODO: Process recording and generate notes
        print("🎬 Processing meeting: \(meeting.title)")
        
        // Simulate processing
        try? await Task.sleep(nanoseconds: 2_000_000_000)
        
        // For now, just mark as ready (in real app, this would happen after transcription)
        meetings[index].status = .ready
        saveMeetings()
    }
    
    func requestPermissions() async {
        let calendarGranted = await calendarService.requestAccess()
        print(calendarGranted ? "✅ Calendar access granted" : "❌ Calendar access denied")
    }
    
    private func saveMeetings() {
        if let encoded = try? JSONEncoder().encode(meetings) {
            UserDefaults.standard.set(encoded, forKey: "meetings")
        }
    }
    
    func loadMeetings() {
        if let data = UserDefaults.standard.data(forKey: "meetings"),
           let decoded = try? JSONDecoder().decode([Meeting].self, from: data) {
            meetings = decoded
        }
    }
}
