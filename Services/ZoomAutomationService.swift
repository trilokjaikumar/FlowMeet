//
//  ZoomAutomationService.swift
//  ZoomAutoJoiner
//
//  Created by Trilokeshwar Jaikumar on 11/21/25.
//

import Foundation
import AppKit

class ZoomAutomationService {
    static let shared = ZoomAutomationService()
    
    func joinMeetingWithAutomation(_ meeting: Meeting) -> Bool {
        // First, open the meeting normally
        guard ZoomService.shared.joinMeeting(meeting) else {
            return false
        }
        
        // Wait for Zoom window to appear and auto-click join
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            self.clickJoinButton()
        }
        
        // Also try again after 5 seconds in case it takes longer
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            self.clickJoinButton()
        }
        
        return true
    }
    
    private func clickJoinButton() {
        let script = """
        tell application "System Events"
            tell process "zoom.us"
                try
                    set frontmost to true
                    delay 0.5
                    -- Try to click "Join" button
                    click button "Join" of window 1
                on error
                    try
                        -- Alternative: Try "Join Meeting" button
                        click button "Join Meeting" of window 1
                    on error
                        try
                            -- Last resort: press Enter key
                            keystroke return
                        end try
                    end try
                end try
            end tell
        end tell
        """
        
        if let appleScript = NSAppleScript(source: script) {
            var error: NSDictionary?
            appleScript.executeAndReturnError(&error)
            
            if let error = error {
                print("AppleScript error: \(error)")
            } else {
                print("Successfully automated join button click")
            }
        }
    }
    
    // Helper to check if Zoom is running
    func isZoomRunning() -> Bool {
        let runningApps = NSWorkspace.shared.runningApplications
        return runningApps.contains { $0.bundleIdentifier == "us.zoom.xos" }
    }
}
