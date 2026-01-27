//
//  SourceBadge.swift
//  ZoomAutoJoiner
//
//  Created by Trilokeshwar Jaikumar on 11/21/25.
//

import SwiftUI

struct SourceBadge: View {
    let source: MeetingSource
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: source.icon)
            Text(source.rawValue)
        }
        .font(.caption)
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(Color.gray.opacity(0.2))
        .foregroundColor(.secondary)
        .cornerRadius(4)
    }
}
