//
//  FlowMeetApp.swift
//  FlowMeet
//
//  Created by Trilokeshwar Jaikumar on 1/27/26.
//

import Foundation
import SwiftUI

@main
struct FlowMeetApp: App {
    @StateObject private var meetingListViewModel = MeetingListViewModel()
    @StateObject private var settingsViewModel = SettingsViewModel()
    
    var body: some Scene {
        WindowGroup {
            DashboardView()
                .environmentObject(meetingListViewModel)
                .environmentObject(settingsViewModel)
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
