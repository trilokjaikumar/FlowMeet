//
//  ZoomService.swift
//  ZoomAutoJoiner
//
//  Created by Trilokeshwar Jaikumar on 11/21/25.
//

import Foundation
import AppKit

class ZoomService {
    static let shared = ZoomService()
    
    func joinMeeting(_ meeting: Meeting) -> Bool {
        guard meeting.hasZoomInfo else {
            print("❌ No Zoom info available for meeting: \(meeting.title)")
            return false
        }
        
        var urlToOpen: URL?
        
        if let zoomUrl = meeting.zoomUrl {
            print("============================================================")
            print("ORIGINAL ZOOM URL: \(zoomUrl)")
            print("URL LENGTH: \(zoomUrl.count) characters")
            
            if let meetingId = ZoomURLParser.extractZoomId(from: zoomUrl) {
                print("EXTRACTED MEETING ID: [\(meetingId)]")
                print("MEETING ID LENGTH: \(meetingId.count) digits")
                
                let passcode = ZoomURLParser.extractPasscode(from: zoomUrl) ?? ""
                if !passcode.isEmpty {
                    print("EXTRACTED PASSCODE: [\(passcode)]")
                }
                
                // Build URL step by step
                let baseUrl = "zoommtg://zoom.us/join"
                let confnoParam = "confno=\(meetingId)"
                let pwdParam = "pwd=\(passcode)"
                let additionalParams = "zc=0&stype=100"
                
                let fullUrl = "\(baseUrl)?\(confnoParam)&\(pwdParam)&\(additionalParams)"
                
                print("CONSTRUCTED URL: \(fullUrl)")
                print("CONFNO PARAM: \(confnoParam)")
                print("============================================================")
                
                urlToOpen = URL(string: fullUrl)
            } else {
                print("⚠️ Could not extract meeting ID, using original URL")
                urlToOpen = URL(string: zoomUrl)
            }
        } else if let zoomId = meeting.zoomId {
            print("============================================================")
            print("MANUAL MEETING ID: [\(zoomId)]")
            print("ID LENGTH: \(zoomId.count) digits")
            let passcodeParam = meeting.zoomPasscode ?? ""
            
            let zoomMtgUrl = "zoommtg://zoom.us/join?confno=\(zoomId)&pwd=\(passcodeParam)&zc=0&stype=100"
            print("CONSTRUCTED URL: \(zoomMtgUrl)")
            print("============================================================")
            
            urlToOpen = URL(string: zoomMtgUrl)
        }
        
        guard let url = urlToOpen else {
            print("❌ Failed to construct Zoom URL")
            return false
        }
        
        print("🚀 FINAL URL TO OPEN: \(url.absoluteString)")
        print("URL COMPONENTS:")
        if let components = URLComponents(url: url, resolvingAgainstBaseURL: false) {
            print("  Scheme: \(components.scheme ?? "none")")
            print("  Host: \(components.host ?? "none")")
            print("  Path: \(components.path)")
            print("  Query: \(components.query ?? "none")")
            if let queryItems = components.queryItems {
                for item in queryItems {
                    print("    \(item.name) = \(item.value ?? "empty")")
                }
            }
        }
        
        NSWorkspace.shared.open(url)
        print("✅ Zoom should be opening now...")
        return true
    }
    
    func canJoinMeeting(_ meeting: Meeting, offsetMinutes: Int) -> Bool {
        let now = Date()
        let joinTime = meeting.startDate.addingTimeInterval(TimeInterval(-offsetMinutes * 60))
        return now >= joinTime && now <= meeting.endDate
    }
}
