//
//  ModeBadge.swift
//  ZoomAutoJoiner
//
//  Created by Trilokeshwar Jaikumar on 11/21/25.
//

import SwiftUI

struct ModeBadge: View {
    let mode: MeetingMode
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
            Text(mode.displayName)
        }
        .font(.caption)
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(backgroundColor)
        .foregroundColor(foregroundColor)
        .cornerRadius(4)
    }
    
    private var icon: String {
        switch mode {
        case .incognito:
            return "eye.slash.fill"
        case .transparent:
            return "eye.fill"
        }
    }
    
    private var backgroundColor: Color {
        switch mode {
        case .incognito:
            return Color.orange.opacity(0.2)
        case .transparent:
            return Color.green.opacity(0.2)
        }
    }
    
    private var foregroundColor: Color {
        switch mode {
        case .incognito:
            return .orange
        case .transparent:
            return .green
        }
    }
}
