//
//  SettingsView.swift
//  ZoomAutoJoiner
//
//  Created by Trilokeshwar Jaikumar on 11/21/25.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var viewModel: SettingsViewModel
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            GeneralSettingsView()
                .tabItem { Label("General", systemImage: "gear") }
                .tag(0)
            
            CalendarSettingsView()
                .tabItem { Label("Calendar", systemImage: "calendar") }
                .tag(1)
            
            AudioSettingsView()
                .tabItem { Label("Audio", systemImage: "waveform") }
                .tag(2)
            
            OpenAISettingsView()
                .tabItem { Label("OpenAI", systemImage: "brain") }
                .tag(3)
        }
        .frame(width: 600, height: 500)
        .padding()
    }
}

// MARK: - General Settings

struct GeneralSettingsView: View {
    @EnvironmentObject var viewModel: SettingsViewModel
    
    var body: some View {
        Form {
            Section("Meeting Behavior") {
                Picker("Auto-join offset", selection: $viewModel.settings.joinOffsetMinutes) {
                    Text("At start time").tag(0)
                    Text("1 minute before").tag(1)
                    Text("2 minutes before").tag(2)
                    Text("5 minutes before").tag(5)
                }
                
                Picker("Default mode", selection: $viewModel.settings.defaultMode) {
                    ForEach(MeetingMode.allCases, id: \.self) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
            }
            
            Section("Recording Modes") {
                VStack(alignment: .leading, spacing: 12) {
                    Toggle("Enable Incognito Mode", isOn: Binding(
                        get: { viewModel.settings.incognitoEnabled },
                        set: { viewModel.toggleIncognito($0) }
                    ))
                    
                    Text("In Incognito mode, the app does not notify other participants. You are responsible for complying with local laws and meeting policies.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    if viewModel.settings.incognitoEnabled {
                        GroupBox {
                            VStack(alignment: .leading, spacing: 8) {
                                Label("Incognito Mode Active", systemImage: "exclamationmark.triangle.fill")
                                    .foregroundColor(.orange)
                                    .bold()
                                
                                Text("Always ensure you have permission to record meetings and comply with applicable laws.")
                                    .font(.caption)
                            }
                        }
                    }
                }
            }
            
            Section("Transparency") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Meeting Disclosure")
                        .font(.headline)
                    
                    Text("Copy this message to inform participants:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    TextEditor(text: .constant(MeetingMode.transparent.disclosureSnippet))
                        .frame(height: 80)
                        .font(.system(.body, design: .monospaced))
                        .border(Color.gray.opacity(0.3))
                    
                    Button("Copy to Clipboard") {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(MeetingMode.transparent.disclosureSnippet, forType: .string)
                    }
                }
            }
        }
        .formStyle(.grouped)
        .alert("Incognito Mode Warning", isPresented: $viewModel.showIncognitoWarning) {
            Button("Cancel", role: .cancel) { }
            Button("I Understand", role: .destructive) {
                viewModel.acknowledgeIncognitoWarning()
            }
        } message: {
            Text(MeetingMode.incognito.warningMessage)
        }
        .onChange(of: viewModel.settings) { _ in
            viewModel.saveSettings()
        }
    }
}

// MARK: - Calendar Settings

struct CalendarSettingsView: View {
    @EnvironmentObject var viewModel: SettingsViewModel
    
    var body: some View {
        Form {
            Section("Calendar Sources") {
                Toggle("Apple Calendar", isOn: $viewModel.settings.appleCalendarEnabled)
                
                Toggle("Google Calendar", isOn: $viewModel.settings.googleCalendarEnabled)
                    .disabled(true)
                
                if !viewModel.settings.googleCalendarEnabled {
                    Text("Google Calendar integration coming soon")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Section("Sync Settings") {
                Stepper("Sync next \(viewModel.settings.calendarSyncDays) days",
                       value: $viewModel.settings.calendarSyncDays,
                       in: 1...30)
            }
            
            Section("Permissions") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Calendar Access")
                        .font(.headline)
                    
                    Text("This app needs permission to read your calendar events to automatically detect Zoom meetings.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    Button("Open System Preferences") {
                        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Calendars") {
                            NSWorkspace.shared.open(url)
                        }
                    }
                }
            }
        }
        .formStyle(.grouped)
        .onChange(of: viewModel.settings) { _ in
            viewModel.saveSettings()
        }
    }
}

// MARK: - Audio Settings

struct AudioSettingsView: View {
    @EnvironmentObject var viewModel: SettingsViewModel
    
    var body: some View {
        Form {
            Section("Audio Source") {
                Picker("Capture mode", selection: $viewModel.settings.audioSource) {
                    ForEach(AudioSource.allCases, id: \.self) { source in
                        Text(source.rawValue).tag(source)
                    }
                }
                
                Text(viewModel.settings.audioSource.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            if viewModel.settings.audioSource == .systemAudio {
                Section("System Audio Setup") {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("To capture system audio, you need a virtual audio device:")
                            .font(.headline)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("1. Install BlackHole (free, open-source)")
                            Link("Download BlackHole", destination: URL(string: "https://existential.audio/blackhole/")!)
                            
                            Text("2. Set up Multi-Output Device in Audio MIDI Setup")
                            Text("3. Configure Zoom to output to BlackHole")
                            Text("4. Select BlackHole as input in this app")
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                }
            }
            
            Section("Permissions") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Microphone Access")
                        .font(.headline)
                    
                    Text("This app needs permission to access your microphone for recording meetings.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    Button("Open System Preferences") {
                        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Microphone") {
                            NSWorkspace.shared.open(url)
                        }
                    }
                }
            }
        }
        .formStyle(.grouped)
        .onChange(of: viewModel.settings) { _ in
            viewModel.saveSettings()
        }
    }
}

// MARK: - OpenAI Settings

struct OpenAISettingsView: View {
    @EnvironmentObject var viewModel: SettingsViewModel
    @State private var showKey = false
    @State private var isTesting = false
    @State private var testResult: String?
    
    var body: some View {
        Form {
            Section("API Configuration") {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        if showKey {
                            TextField("API Key", text: $viewModel.tempOpenAIKey)
                                .textFieldStyle(.roundedBorder)
                        } else {
                            SecureField("API Key", text: $viewModel.tempOpenAIKey)
                                .textFieldStyle(.roundedBorder)
                        }
                        
                        Button(action: { showKey.toggle() }) {
                            Image(systemName: showKey ? "eye.slash" : "eye")
                        }
                    }
                    
                    Text("Get your API key from platform.openai.com")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        Button("Test Connection") {
                            testConnection()
                        }
                        .disabled(viewModel.tempOpenAIKey.isEmpty || isTesting)
                        
                        if isTesting {
                            ProgressView()
                                .scaleEffect(0.7)
                        }
                        
                        if let result = testResult {
                            Text(result)
                                .font(.caption)
                                .foregroundColor(result.contains("Success") ? .green : .red)
                        }
                    }
                }
            }
            
            Section("Models") {
                Picker("Transcription model", selection: $viewModel.settings.transcriptionModel) {
                    Text("whisper-1").tag("whisper-1")
                }
                
                Picker("Notes generation model", selection: $viewModel.settings.notesModel) {
                    Text("GPT-4 Turbo").tag("gpt-4-turbo-preview")
                    Text("GPT-4").tag("gpt-4")
                    Text("GPT-3.5 Turbo").tag("gpt-3.5-turbo")
                }
            }
            
            Section("Cost Estimation") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Approximate costs per 1-hour meeting:")
                        .font(.headline)
                    
                    Text("• Transcription (Whisper): ~$0.36")
                    Text("• Notes (GPT-4 Turbo): ~$0.10-0.30")
                    Text("• Total: ~$0.50 per meeting")
                    
                    Text("Actual costs depend on audio quality and transcript length.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
                }
            }
        }
        .formStyle(.grouped)
        .onChange(of: viewModel.tempOpenAIKey) { _ in
            testResult = nil
            viewModel.saveSettings()
        }
        .onChange(of: viewModel.settings) { _ in
            viewModel.saveSettings()
        }
    }
    
    private func testConnection() {
        isTesting = true
        testResult = nil
        
        Task {
            let success = await viewModel.testOpenAIConnection()
            await MainActor.run {
                isTesting = false
                testResult = success ? "✓ Connection successful" : "✗ Connection failed"
            }
        }
    }
}
