//
//  MeetingListViewModel.swift
//  ZoomAutoJoiner
//
//  Created by Trilokeshwar Jaikumar on 11/21/25.
//

import Foundation
import Combine

@MainActor
class MeetingListViewModel: ObservableObject {
    @Published var meetings: [Meeting] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let persistenceService = PersistenceService.shared
    private let calendarService = CalendarService()
    private let audioService = AudioCaptureService()
    private let scheduler = MeetingScheduler.shared
    
    init() {
        loadMeetings()
    }
    
    func loadMeetings() {
        meetings = persistenceService.loadMeetings()
        sortMeetings()
    }
    
    func saveMeetings() {
        persistenceService.saveMeetings(meetings)
    }
    
    func addMeeting(_ meeting: Meeting) {
        meetings.append(meeting)
        sortMeetings()
        saveMeetings()
    }
    
    func updateMeeting(_ meeting: Meeting) {
        if let index = meetings.firstIndex(where: { $0.id == meeting.id }) {
            meetings[index] = meeting
            saveMeetings()
        }
    }
    
    func deleteMeeting(_ meeting: Meeting) {
        meetings.removeAll { $0.id == meeting.id }
        scheduler.cancelMeeting(meeting.id)
        saveMeetings()
    }
    
    func scheduleAutoEnd(for meeting: Meeting) {
        let endTime = meeting.endDate
        let timeInterval = endTime.timeIntervalSinceNow
        
        guard timeInterval > 0 else {
            print("⏰ Meeting has already ended: \(meeting.title)")
            return
        }
        
        // Schedule end action
        DispatchQueue.main.asyncAfter(deadline: .now() + timeInterval) { [weak self] in
            Task { @MainActor in
                await self?.handleMeetingEnd(meeting)
            }
        }
        
        let minutes = Int(timeInterval / 60)
        print("⏰ Scheduled auto-end for '\(meeting.title)' in \(minutes) minutes")
    }

    func handleMeetingEnd(_ meeting: Meeting) async {
        print("⏰ Meeting ended: \(meeting.title)")
        
        // Check if meeting is currently being recorded
        guard meeting.status == .inProgress else {
            print("   Meeting was not in progress, skipping recording stop")
            return
        }
        
        print("   Stopping recording and processing notes...")
        
        // Stop recording and process
        await stopRecording(for: meeting)
    }
    func syncCalendars(settings: AppSettings) async {
        isLoading = true
        errorMessage = nil
        
        var newMeetings: [Meeting] = []
        
        // Sync Apple Calendar
        if settings.appleCalendarEnabled {
            let hasAccess = await calendarService.requestAccess()
            if hasAccess {
                let appleCalendarMeetings = await calendarService.fetchUpcomingZoomMeetings(days: settings.calendarSyncDays)
                newMeetings.append(contentsOf: appleCalendarMeetings)
            }
        }
        
        // Remove old calendar meetings and add new ones
        meetings.removeAll { $0.source == .appleCalendar || $0.source == .googleCalendar }
        meetings.append(contentsOf: newMeetings)
        
        sortMeetings()
        saveMeetings()
        isLoading = false
    }
    
    func scheduleAutoJoin(for meeting: Meeting, settings: AppSettings) {
        scheduler.scheduleMeeting(meeting, offsetMinutes: settings.joinOffsetMinutes) { [weak self] meeting in
            self?.handleAutoJoin(meeting)
        }
    }
    
    func handleAutoJoin(_ meeting: Meeting) {
        // Use automation service for true auto-join
        let joined = ZoomAutomationService.shared.joinMeetingWithAutomation(meeting)
        
        if joined {
            // Update status
            var updatedMeeting = meeting
            updatedMeeting.status = .inProgress
            updateMeeting(updatedMeeting)
            
            // Schedule automatic end
            scheduleAutoEnd(for: updatedMeeting)
            
            // Start recording after a delay (give Zoom time to fully join)
            Task {
                // Wait 8 seconds for Zoom to fully join before starting recording
                try? await Task.sleep(nanoseconds: 8_000_000_000)
                
                let started = await audioService.startRecording(for: meeting)
                if started {
                    print("Recording started for: \(meeting.title)")
                }
            }
        }
    }
    
    func stopRecording(for meeting: Meeting) async {
        guard let recordingURL = await audioService.stopRecording() else {
            var updatedMeeting = meeting
            updatedMeeting.status = .failed
            updateMeeting(updatedMeeting)
            return
        }
        
        // Update meeting with recording path
        var updatedMeeting = meeting
        updatedMeeting.recordingPath = recordingURL.path
        updatedMeeting.status = .processing
        updateMeeting(updatedMeeting)
        
        // Process recording
        await processRecording(for: updatedMeeting, recordingURL: recordingURL)
    }
    
    func processRecording(for meeting: Meeting, recordingURL: URL) async {
        print("============================================================")
        print("📝 PROCESSING RECORDING")
        print("   Meeting: \(meeting.title)")
        print("   Recording: \(recordingURL.lastPathComponent)")
        print("============================================================")
        
        guard let apiKey = KeychainManager.shared.load(key: "openai_api_key") else {
            var updatedMeeting = meeting
            updatedMeeting.status = .failed
            updateMeeting(updatedMeeting)
            errorMessage = "OpenAI API key not found. Please add it in Settings."
            print("❌ ERROR: No OpenAI API key found")
            return
        }
        
        do {
            // Transcribe audio
            print("🎤 Starting transcription...")
            let transcript = try await OpenAIService.shared.transcribeAudio(
                fileURL: recordingURL,
                apiKey: apiKey
            )
            print("✅ Transcription complete (\(transcript.count) characters)")
            
            // Generate notes
            print("🤖 Generating AI notes...")
            let notes = try await OpenAIService.shared.generateNotes(
                transcript: transcript,
                apiKey: apiKey
            )
            print("✅ Notes generated successfully")
            print("   Summary: \(notes.summary.prefix(100))...")
            print("   Takeaways: \(notes.keyTakeaways.count)")
            print("   Action Items: \(notes.actionItems.count)")
            
            // Update meeting
            var updatedMeeting = meeting
            updatedMeeting.notes = notes
            updatedMeeting.status = .ready
            updatedMeeting.updatedAt = Date()
            updateMeeting(updatedMeeting)
            
            print("✅ Meeting notes saved successfully!")
            print("============================================================")
            
        } catch {
            var updatedMeeting = meeting
            updatedMeeting.status = .failed
            updateMeeting(updatedMeeting)
            errorMessage = "Failed to process recording: \(error.localizedDescription)"
            print("❌ ERROR: \(error.localizedDescription)")
            print("============================================================")
        }
    }
    
    private func sortMeetings() {
        meetings.sort { $0.startDate < $1.startDate }
    }
    
    var upcomingMeetings: [Meeting] {
        meetings.filter { !$0.hasEnded }
    }

    var pastMeetings: [Meeting] {
        meetings.filter { $0.hasEnded }
    }
}
