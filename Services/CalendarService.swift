//
//  CalendarService.swift
//  ZoomAutoJoiner
//
//  Created by Trilokeshwar Jaikumar on 11/21/25.
//

import Foundation
import EventKit
import Combine

class CalendarService: ObservableObject {
    private let eventStore = EKEventStore()
    @Published var authorizationStatus: EKAuthorizationStatus = .notDetermined
    
    func requestAccess() async -> Bool {
        if #available(macOS 14.0, *) {
            do {
                let granted = try await eventStore.requestFullAccessToEvents()
                await MainActor.run {
                    self.authorizationStatus = granted ? .fullAccess : .denied
                }
                return granted
            } catch {
                print("Calendar access error: \(error)")
                return false
            }
        } else {
            return await withCheckedContinuation { continuation in
                eventStore.requestAccess(to: .event) { granted, error in
                    DispatchQueue.main.async {
                        self.authorizationStatus = granted ? .authorized : .denied
                    }
                    continuation.resume(returning: granted)
                }
            }
        }
    }
    
    func fetchUpcomingZoomMeetings(days: Int) async -> [Meeting] {
        guard authorizationStatus == .fullAccess || authorizationStatus == .authorized else {
            return []
        }
        
        let startDate = Date()
        let endDate = Calendar.current.date(byAdding: .day, value: days, to: startDate)!
        
        let predicate = eventStore.predicateForEvents(
            withStart: startDate,
            end: endDate,
            calendars: nil
        )
        
        let events = eventStore.events(matching: predicate)
        var meetings: [Meeting] = []
        
        for event in events {
            if let zoomUrl = extractZoomUrl(from: event) {
                let meeting = Meeting(
                    title: event.title ?? "Untitled Meeting",
                    startDate: event.startDate,
                    duration: event.endDate.timeIntervalSince(event.startDate),
                    zoomUrl: zoomUrl,
                    source: .appleCalendar,
                    calendarEventId: event.eventIdentifier
                )
                meetings.append(meeting)
            }
        }
        
        return meetings
    }
    
    private func extractZoomUrl(from event: EKEvent) -> String? {
        let combinedText = """
        \(event.title ?? "") 
        \(event.notes ?? "") 
        \(event.location ?? "") 
        \(event.url?.absoluteString ?? "")
        """
        
        return ZoomURLParser.extractZoomUrl(from: combinedText)
    }
}
