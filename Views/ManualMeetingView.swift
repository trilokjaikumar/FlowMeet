//
//  ManualMeetingView.swift
//  ZoomAutoJoiner
//
//  Created by Trilokeshwar Jaikumar on 11/21/25.
//

import SwiftUI

struct ManualMeetingView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var settingsViewModel: SettingsViewModel
    
    @State private var title = ""
    @State private var startDate = Date()
    @State private var duration: Double = 60 // minutes
    @State private var zoomUrl = ""
    @State private var zoomId = ""
    @State private var zoomPasscode = ""
    @State private var inputMethod = 0 // 0 = URL, 1 = ID+Passcode
    
    @State private var showingValidationError = false
    @State private var validationMessage = ""
    
    let onSave: (Meeting) -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Add Meeting Manually")
                    .font(.title2)
                    .bold()
                
                Spacer()
                
                Button("Cancel") {
                    dismiss()
                }
            }
            .padding()
            
            Divider()
            
            // Form
            Form {
                Section("Meeting Details") {
                    TextField("Title", text: $title)
                    
                    DatePicker("Start Time", selection: $startDate, in: Date()...)
                    
                    HStack {
                        Text("Duration")
                        Spacer()
                        TextField("60", value: $duration, format: .number)
                            .frame(width: 60)
                            .textFieldStyle(.roundedBorder)
                        Text("minutes")
                    }
                }
                
                Section("Zoom Information") {
                    Picker("Input Method", selection: $inputMethod) {
                        Text("Zoom URL").tag(0)
                        Text("Meeting ID + Passcode").tag(1)
                    }
                    .pickerStyle(.segmented)
                    
                    if inputMethod == 0 {
                        VStack(alignment: .leading, spacing: 4) {
                            TextField("https://zoom.us/j/123456789?pwd=abc", text: $zoomUrl)
                            
                            Text("Example: https://zoom.us/j/1234567890 or https://company.zoom.us/j/9876543210?pwd=abc123")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    } else {
                        VStack(alignment: .leading, spacing: 8) {
                            VStack(alignment: .leading, spacing: 4) {
                                TextField("Meeting ID (numbers only)", text: $zoomId)
                                    .onChange(of: zoomId) { newValue in
                                        // Filter to numbers only
                                        zoomId = newValue.filter { $0.isNumber }
                                    }
                                
                                Text("Example: 1234567890 (10-11 digits)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                TextField("Passcode (optional)", text: $zoomPasscode)
                                
                                Text("Usually 6 alphanumeric characters")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
            .formStyle(.grouped)
            
            Divider()
            
            // Footer
            HStack {
                Spacer()
                
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
                
                Button("Add Meeting") {
                    validateAndSave()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(!isBasicInfoValid)
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
        .frame(width: 500, height: 500)
        .alert("Invalid Input", isPresented: $showingValidationError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(validationMessage)
        }
    }
    
    private var isBasicInfoValid: Bool {
        !title.isEmpty && (
            (inputMethod == 0 && !zoomUrl.isEmpty) ||
            (inputMethod == 1 && !zoomId.isEmpty)
        )
    }
    
    private func validateAndSave() {
        // Validate based on input method
        if inputMethod == 0 {
            // Validate URL
            if !isValidZoomUrl(zoomUrl) {
                validationMessage = "Invalid Zoom URL. Please enter a valid Zoom meeting URL like:\n\nhttps://zoom.us/j/1234567890\nor\nhttps://company.zoom.us/j/9876543210?pwd=abc123"
                showingValidationError = true
                return
            }
        } else {
            // Validate Meeting ID
            if !isValidMeetingId(zoomId) {
                validationMessage = "Invalid Meeting ID. Meeting IDs must be 10-11 digits.\n\nExample: 1234567890"
                showingValidationError = true
                return
            }
        }
        
        // If validation passes, save the meeting
        saveMeeting()
    }
    
    private func isValidZoomUrl(_ url: String) -> Bool {
        // Check if it's a valid Zoom URL pattern
        let patterns = [
            "https?://[a-zA-Z0-9.-]*\\.?zoom\\.us/j/[0-9]{10,11}",
            "https?://[a-zA-Z0-9.-]*\\.?zoom\\.us/s/[0-9]{10,11}",
            "https?://[a-zA-Z0-9.-]*\\.?zoom\\.us/[jw]/[0-9]{10,11}"
        ]
        
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                let range = NSRange(url.startIndex..., in: url)
                if regex.firstMatch(in: url, range: range) != nil {
                    return true
                }
            }
        }
        
        return false
    }
    
    private func isValidMeetingId(_ id: String) -> Bool {
        // Meeting IDs are typically 10-11 digits
        let digitsOnly = id.filter { $0.isNumber }
        return digitsOnly.count >= 9 && digitsOnly.count <= 11 && digitsOnly == id
    }
    
    private func saveMeeting() {
        // Strip spaces from meeting ID (just in case)
        let cleanedZoomId = zoomId.replacingOccurrences(of: " ", with: "")
        
        let meeting = Meeting(
            title: title,
            startDate: startDate,
            duration: duration * 60, // Convert to seconds
            zoomUrl: inputMethod == 0 ? zoomUrl : nil,
            zoomId: inputMethod == 1 ? cleanedZoomId : nil,
            zoomPasscode: inputMethod == 1 && !zoomPasscode.isEmpty ? zoomPasscode : nil,
            source: .manual,
            mode: settingsViewModel.settings.defaultMode
        )
        
        onSave(meeting)
        dismiss()
    }
}
