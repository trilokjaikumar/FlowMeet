//
//  Meeting.swift
//  ZoomAutoJoiner
//
//  Created by Trilokeshwar Jaikumar on 11/20/25.
//

import Foundation

struct Meeting: Identifiable, Codable, Hashable {
    var id: UUID
    var title: String
    var startDate: Date
    var duration: TimeInterval
    var zoomUrl: String?
    var zoomId: String?
    var zoomPasscode: String?
    var source: MeetingSource
    var mode: MeetingMode
    var notes: MeetingNotes?
    var recordingPath: String?
    var transcriptPath: String?
    var status: MeetingStatus
    var calendarEventId: String?
    var createdAt: Date
    var updatedAt: Date
    
    init(
        id: UUID = UUID(),
        title: String,
        startDate: Date,
        duration: TimeInterval = 3600,
        zoomUrl: String? = nil,
        zoomId: String? = nil,
        zoomPasscode: String? = nil,
        source: MeetingSource,
        mode: MeetingMode = .transparent,
        calendarEventId: String? = nil
    ) {
        self.id = id
        self.title = title
        self.startDate = startDate
        self.duration = duration
        self.zoomUrl = zoomUrl
        self.zoomId = zoomId
        self.zoomPasscode = zoomPasscode
        self.source = source
        self.mode = mode
        self.notes = nil
        self.recordingPath = nil
        self.transcriptPath = nil
        self.status = .notStarted
        self.calendarEventId = calendarEventId
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    var endDate: Date {
        startDate.addingTimeInterval(duration)
    }
    
    var isUpcoming: Bool {
        let now = Date()
        // Meeting is upcoming if it hasn't ended yet
        return endDate > now
    }

    var isInProgress: Bool {
        let now = Date()
        // Meeting is in progress if we're between start and end
        return now >= startDate && now < endDate
    }

    var hasEnded: Bool {
        let now = Date()
        // Meeting has ended if current time is past the end time
        return now >= endDate
    }
    
    var hasZoomInfo: Bool {
        zoomUrl != nil || (zoomId != nil && !zoomId!.isEmpty)
    }
}

enum MeetingStatus: String, Codable {
    case notStarted = "Not Started"
    case inProgress = "In Progress"
    case processing = "Processing"
    case ready = "Ready"
    case failed = "Failed"
}
