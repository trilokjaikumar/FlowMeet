//
//  ZoomURLParser.swift
//  ZoomAutoJoiner
//
//  Created by Trilokeshwar Jaikumar on 11/21/25.
//

import Foundation

struct ZoomURLParser {
    static func extractZoomUrl(from text: String) -> String? {
        let patterns = [
            "https?://[a-zA-Z0-9.-]*\\.?zoom\\.us/j/[0-9]+(?:\\?pwd=[a-zA-Z0-9]+)?",
            "https?://[a-zA-Z0-9.-]*\\.?zoom\\.us/[sw]/[0-9]+(?:\\?[^\\s]*)?",
            "zoommtg://[^\\s]+"
        ]
        
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                let range = NSRange(text.startIndex..., in: text)
                if let match = regex.firstMatch(in: text, range: range) {
                    if let matchRange = Range(match.range, in: text) {
                        return String(text[matchRange])
                    }
                }
            }
        }
        
        return nil
    }
    
    static func extractZoomId(from url: String) -> String? {
        // Try multiple patterns for meeting ID extraction
        let patterns = [
            "/j/([0-9]+)",
            "/s/([0-9]+)",
            "confno=([0-9]+)",
            "confno%3D([0-9]+)"
        ]
        
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
                let range = NSRange(url.startIndex..., in: url)
                if let match = regex.firstMatch(in: url, range: range),
                   match.numberOfRanges > 1,
                   let idRange = Range(match.range(at: 1), in: url) {
                    let meetingId = String(url[idRange])
                    print("Extracted meeting ID: \(meetingId)")
                    return meetingId
                }
            }
        }
        
        print("Failed to extract meeting ID from: \(url)")
        return nil
    }
    
    static func extractPasscode(from url: String) -> String? {
        let patterns = [
            "pwd=([a-zA-Z0-9]+)",
            "pwd%3D([a-zA-Z0-9]+)"
        ]
        
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
                let range = NSRange(url.startIndex..., in: url)
                if let match = regex.firstMatch(in: url, range: range),
                   match.numberOfRanges > 1,
                   let pwdRange = Range(match.range(at: 1), in: url) {
                    let passcode = String(url[pwdRange])
                    print("Extracted passcode: \(passcode)")
                    return passcode
                }
            }
        }
        
        return nil
    }
}
