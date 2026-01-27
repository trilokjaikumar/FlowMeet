//
//  PersistenceService.swift
//  ZoomAutoJoiner
//
//  Created by Trilokeshwar Jaikumar on 11/21/25.
//

import Foundation

class PersistenceService {
    static let shared = PersistenceService()
    
    private let meetingsKey = "saved_meetings"
    private let settingsKey = "app_settings"
    
    private var documentsDirectory: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    private var meetingsFileURL: URL {
        documentsDirectory.appendingPathComponent("meetings.json")
    }
    
    private var settingsFileURL: URL {
        documentsDirectory.appendingPathComponent("settings.json")
    }
    
    // MARK: - Meetings
    
    func saveMeetings(_ meetings: [Meeting]) {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(meetings)
            try data.write(to: meetingsFileURL)
            print("Saved \(meetings.count) meetings")
        } catch {
            print("Failed to save meetings: \(error)")
        }
    }
    
    func loadMeetings() -> [Meeting] {
        guard FileManager.default.fileExists(atPath: meetingsFileURL.path) else {
            return []
        }
        
        do {
            let data = try Data(contentsOf: meetingsFileURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let meetings = try decoder.decode([Meeting].self, from: data)
            print("Loaded \(meetings.count) meetings")
            return meetings
        } catch {
            print("Failed to load meetings: \(error)")
            return []
        }
    }
    
    // MARK: - Settings
    
    func saveSettings(_ settings: AppSettings) {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(settings)
            try data.write(to: settingsFileURL)
        } catch {
            print("Failed to save settings: \(error)")
        }
    }
    
    func loadSettings() -> AppSettings {
        guard FileManager.default.fileExists(atPath: settingsFileURL.path) else {
            return AppSettings()
        }
        
        do {
            let data = try Data(contentsOf: settingsFileURL)
            let settings = try JSONDecoder().decode(AppSettings.self, from: data)
            return settings
        } catch {
            print("Failed to load settings: \(error)")
            return AppSettings()
        }
    }
}
