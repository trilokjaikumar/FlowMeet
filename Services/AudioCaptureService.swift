//
//  AudioCaptureService.swift
//  ZoomAutoJoiner
//
//  Created by Trilokeshwar Jaikumar on 11/21/25.
//

import Foundation
import AVFoundation
import CoreAudio
import Combine

class AudioCaptureService: NSObject, ObservableObject {
    @Published var isRecording = false
    @Published var currentMeetingId: UUID?
    
    private var audioEngine: AVAudioEngine?
    private var audioFile: AVAudioFile?
    private var recordingURL: URL?
    
    func startRecording(for meeting: Meeting) async -> Bool {
        guard !isRecording else { return false }
        
        // Request microphone permission
        let permission = await AVCaptureDevice.requestAccess(for: .audio)
        guard permission else {
            print("Microphone permission denied")
            return false
        }
        
        // Create recordings directory if needed
        let recordingsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("recordings")
        
        try? FileManager.default.createDirectory(at: recordingsDir, withIntermediateDirectories: true)
        
        // Set up recording file
        let filename = "\(meeting.id.uuidString).m4a"
        recordingURL = recordingsDir.appendingPathComponent(filename)
        
        do {
            audioEngine = AVAudioEngine()
            guard let engine = audioEngine else { return false }
            
            let inputNode = engine.inputNode
            let inputFormat = inputNode.outputFormat(forBus: 0)
            
            // Create audio file
            let settings: [String: Any] = [
                AVFormatIDKey: kAudioFormatMPEG4AAC,
                AVSampleRateKey: 44100.0,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]
            
            audioFile = try AVAudioFile(
                forWriting: recordingURL!,
                settings: settings
            )
            
            // Install tap
            inputNode.installTap(onBus: 0, bufferSize: 4096, format: inputFormat) { [weak self] buffer, _ in
                try? self?.audioFile?.write(from: buffer)
            }
            
            engine.prepare()
            try engine.start()
            
            await MainActor.run {
                self.isRecording = true
                self.currentMeetingId = meeting.id
            }
            
            print("Started recording for meeting: \(meeting.title)")
            return true
            
        } catch {
            print("Failed to start recording: \(error)")
            return false
        }
    }
    
    func stopRecording() async -> URL? {
        guard isRecording, let engine = audioEngine else { return nil }
        
        engine.inputNode.removeTap(onBus: 0)
        engine.stop()
        audioFile = nil
        
        let url = recordingURL
        
        await MainActor.run {
            self.isRecording = false
            self.currentMeetingId = nil
        }
        
        print("Stopped recording. File saved at: \(url?.path ?? "unknown")")
        return url
    }
}
