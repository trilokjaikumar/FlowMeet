//
//  NotificationManager.swift
//  ZoomAutoJoiner
//
//  Created by Trilokeshwar Jaikumar on 11/21/25.
//

import Foundation
import UserNotifications

class NotificationManager {
    static let shared = NotificationManager()
    
    func requestAuthorization() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
            return granted
        } catch {
            print("Notification authorization error: \(error)")
            return false
        }
    }
    
    func scheduleJoinNotification(for meeting: Meeting, minutesBefore: Int = 5) {
        let content = UNMutableNotificationContent()
        content.title = "Upcoming Meeting"
        content.body = "\(meeting.title) starts in \(minutesBefore) minutes"
        content.sound = .default
        
        let triggerDate = meeting.startDate.addingTimeInterval(TimeInterval(-minutesBefore * 60))
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: triggerDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: "meeting-\(meeting.id.uuidString)",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to schedule notification: \(error)")
            }
        }
    }
    
    func cancelNotification(for meetingId: UUID) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: ["meeting-\(meetingId.uuidString)"]
        )
    }
}
