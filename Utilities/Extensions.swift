//
//  Extensions.swift
//  ZoomAutoJoiner
//
//  Created by Trilokeshwar Jaikumar on 11/21/25.
//

import Foundation
import SwiftUI

extension Date {
    func formattedTime() -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: self)
    }
    
    func formattedTimeWithSeconds() -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .medium
        return formatter.string(from: self)
    }
    
    func formattedDate() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: self)
    }
    
    func formattedDateTime() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: self)
    }
    
    func isToday() -> Bool {
        Calendar.current.isDateInToday(self)
    }
    
    func isTomorrow() -> Bool {
        Calendar.current.isDateInTomorrow(self)
    }
    
    func relativeDateString() -> String {
        let now = Date()
        let timeInterval = self.timeIntervalSince(now)
        
        if timeInterval > 0 && timeInterval < 3600 { // Less than 1 hour away
            let minutes = Int(timeInterval / 60)
            let seconds = Int(timeInterval.truncatingRemainder(dividingBy: 60))
            return "In \(minutes)m \(seconds)s"
        } else if isToday() {
            return "Today, \(formattedTime())"
        } else if isTomorrow() {
            return "Tomorrow, \(formattedTime())"
        } else {
            return formattedDateTime()
        }
    }
}

extension Color {
    static let primaryAccent = Color.blue
    static let successGreen = Color.green
    static let warningOrange = Color.orange
    static let errorRed = Color.red
}
