//
//  CalendarSyncViewModel.swift
//  ZoomAutoJoiner
//
//  Created by Trilokeshwar Jaikumar on 11/21/25.
//

import Foundation
import Combine

@MainActor
class CalendarSyncViewModel: ObservableObject {
    @Published var isSyncing = false
    @Published var lastSyncDate: Date?
    @Published var errorMessage: String?
    
    private let calendarService = CalendarService()
    private let googleCalendarService = GoogleCalendarService()
    
    func syncCalendars(settings: AppSettings, completion: @escaping ([Meeting]) -> Void) async {
        isSyncing = true
        errorMessage = nil
        
        var allMeetings: [Meeting] = []
        
        // Apple Calendar
        if settings.appleCalendarEnabled {
            let hasAccess = await calendarService.requestAccess()
            if hasAccess {
                let meetings = await calendarService.fetchUpcomingZoomMeetings(days: settings.calendarSyncDays)
                allMeetings.append(contentsOf: meetings)
            } else {
                errorMessage = "Apple Calendar access denied"
            }
        }
        
        // Google Calendar
        if settings.googleCalendarEnabled {
            let meetings = await googleCalendarService.fetchUpcomingZoomMeetings(days: settings.calendarSyncDays)
            allMeetings.append(contentsOf: meetings)
        }
        
        lastSyncDate = Date()
        isSyncing = false
        completion(allMeetings)
    }
}
