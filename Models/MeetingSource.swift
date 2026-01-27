//
//  MeetingSource.swift
//  ZoomAutoJoiner
//
//  Created by Trilokeshwar Jaikumar on 11/20/25.
//

import Foundation

enum MeetingSource: String, Codable {
    case appleCalendar = "Apple Calendar"
    case googleCalendar = "Google Calendar"
    case manual = "Manual"
    
    var icon: String {
        switch self {
        case .appleCalendar:
            return "calendar"
        case .googleCalendar:
            return "calendar.badge.clock"
        case .manual:
            return "square.and.pencil"
        }
    }
    
    var color: String {
        switch self {
        case .appleCalendar:
            return "blue"
        case .googleCalendar:
            return "green"
        case .manual:
            return "purple"
        }
    }
}
