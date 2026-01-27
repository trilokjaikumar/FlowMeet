//
//  MeetingScheduler.swift
//  ZoomAutoJoiner
//
//  Created by Trilokeshwar Jaikumar on 11/21/25.
//

import Foundation
import Combine

@MainActor
class MeetingScheduler: ObservableObject {
    static let shared = MeetingScheduler()
    
    @Published var scheduledMeetings: [UUID: Timer] = [:]
    
    private init() {}
    
    func scheduleMeeting(_ meeting: Meeting, offsetMinutes: Int, onJoin: @escaping (Meeting) -> Void) {
        // Cancel existing timer if any
        cancelMeeting(meeting.id)
        
        let joinTime = meeting.startDate.addingTimeInterval(TimeInterval(-offsetMinutes * 60))
        let timeInterval = joinTime.timeIntervalSinceNow
        
        guard timeInterval > 0 else {
            print("⏰ Meeting join time has already passed for: \(meeting.title)")
            print("   Join time was: \(joinTime)")
            print("   Current time: \(Date())")
            return
        }
        
        let timer = Timer(timeInterval: timeInterval, repeats: false) { [weak self] _ in
            Task { @MainActor in
                print("⏰ Auto-joining meeting: \(meeting.title)")
                onJoin(meeting)
                self?.scheduledMeetings.removeValue(forKey: meeting.id)
            }
        }
        
        RunLoop.main.add(timer, forMode: .common)
        scheduledMeetings[meeting.id] = timer
        
        let minutes = Int(timeInterval / 60)
        let seconds = Int(timeInterval.truncatingRemainder(dividingBy: 60))
        print("⏰ Scheduled meeting '\(meeting.title)' to join in \(minutes)m \(seconds)s")
        print("   Will join at: \(joinTime)")
    }
    
    func cancelMeeting(_ id: UUID) {
        scheduledMeetings[id]?.invalidate()
        scheduledMeetings.removeValue(forKey: id)
    }
    
    func cancelAllMeetings() {
        scheduledMeetings.values.forEach { $0.invalidate() }
        scheduledMeetings.removeAll()
    }
}
