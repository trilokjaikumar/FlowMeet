//
//  AppSettings.swift
//  ZoomAutoJoiner
//
//  Created by Trilokeshwar Jaikumar on 11/20/25.
//

import Foundation

struct AppSettings: Codable, Equatable {
    var openAIKey: String?
    var transcriptionModel: String
    var notesModel: String
    var joinOffsetMinutes: Int
    var defaultMode: MeetingMode
    var incognitoEnabled: Bool
    var incognitoAcknowledged: Bool
    var appleCalendarEnabled: Bool
    var googleCalendarEnabled: Bool
    var audioSource: AudioSource
    var calendarSyncDays: Int
    
    init() {
        self.openAIKey = nil
        self.transcriptionModel = "whisper-1"
        self.notesModel = "gpt-4-turbo-preview"
        self.joinOffsetMinutes = 1
        self.defaultMode = .transparent
        self.incognitoEnabled = false
        self.incognitoAcknowledged = false
        self.appleCalendarEnabled = true
        self.googleCalendarEnabled = false
        self.audioSource = .microphoneOnly
        self.calendarSyncDays = 7
    }
}

enum AudioSource: String, Codable, CaseIterable, Hashable {
    case microphoneOnly = "Microphone Only"
    case systemAudio = "System Audio + Mic"

    var displayName: String {
        rawValue
    }

    var description: String {
        switch self {
        case .microphoneOnly:
            return "Captures audio from your microphone"
        case .systemAudio:
            return "Captures both system audio and microphone (requires BlackHole or similar)"
        }
    }
}
