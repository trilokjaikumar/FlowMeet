//
//  ZoomAutoJoinerApp.swift
//  ZoomAutoJoiner
//
//  Created by Trilokeshwar Jaikumar on 11/20/25.
//

import SwiftUI

@main
struct ZoomMeetingAssistantApp: App {
    @StateObject private var meetingListViewModel = MeetingListViewModel()
    @StateObject private var settingsViewModel = SettingsViewModel()
    
    var body: some Scene {
        WindowGroup {
            MainView()
                .environmentObject(meetingListViewModel)
                .environmentObject(settingsViewModel)
                .frame(minWidth: 1000, minHeight: 700)
        }
        .commands {
            CommandGroup(replacing: .newItem) { }
        }
        
        Settings {
            SettingsView()
                .environmentObject(settingsViewModel)
        }
    }
}
