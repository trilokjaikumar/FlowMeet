//
//  MeetingMode.swift
//  ZoomAutoJoiner
//
//  Created by Trilokeshwar Jaikumar on 11/20/25.
//

import Foundation

enum MeetingMode: String, Codable, CaseIterable {
    case incognito = "Incognito"
    case transparent = "Transparent"
    
    var description: String {
        switch self {
        case .incognito:
            return "Private AI note-taking. Does not notify participants."
        case .transparent:
            return "AI note-taking with participant notification."
        }
    }
    
    var warningMessage: String {
        switch self {
        case .incognito:
            return """
            ⚠️ In Incognito mode, this app does not notify other participants. 
            You are responsible for complying with local laws and meeting policies.
            
            Are you sure you want to enable Incognito mode?
            """
        case .transparent:
            return """
            In Transparent mode, you'll be prompted to notify participants 
            that AI note-taking is active.
            """
        }
    }
    
    var disclosureSnippet: String {
        """
        📝 This meeting is being recorded with AI-powered note-taking for internal use. 
        Automated transcription and summary will be generated.
        """
    }
}
