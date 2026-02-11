//
//  Constants.swift
//  ZoomAutoJoiner
//
//  Created by Trilokeshwar Jaikumar on 11/21/25.
//

import Foundation

struct Constants {
    struct OpenAI {
        static let defaultTranscriptionModel = "whisper-1"
        static let defaultNotesModel = "gpt-4-turbo-preview"
    }

    struct Meetings {
        static let defaultJoinOffsetMinutes = 1
        static let defaultCalendarSyncDays = 7
    }

    struct Audio {
        static let recordingsDirectory = "recordings"
        static let transcriptsDirectory = "transcripts"
    }

    struct Notifications {
        static let defaultReminderMinutes = 5
    }
}
