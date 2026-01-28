//
//  LiveAudioCaptureService.swift
//  ZoomAutoJoiner
//
//  Created by Trilokeshwar Jaikumar on 11/22/25.
//

import Foundation
import AVFoundation
import Speech
import Combine

class LiveAudioCaptureService: NSObject, ObservableObject {
    @Published var isListening = false
    @Published var latestTranscript = ""
    @Published var accumulatedTranscript = ""
    
    private var audioEngine: AVAudioEngine?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    
    func requestPermissions() async -> Bool {
        // Request speech recognition permission
        let speechStatus = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }
        guard speechStatus == .authorized else {
            print("❌ Speech recognition not authorized")
            return false
        }
        
        // Request microphone permission
        let audioStatus = await AVCaptureDevice.requestAccess(for: .audio)
        guard audioStatus else {
            print("❌ Microphone not authorized")
            return false
        }
        
        return true
    }
    
    func startListening() async -> Bool {
        guard !isListening else { return false }
        
        let hasPermission = await requestPermissions()
        guard hasPermission else { return false }
        
        do {
            try startRecognition()
            await MainActor.run {
                self.isListening = true
            }
            print("🎤 Started live audio listening...")
            return true
        } catch {
            print("❌ Failed to start listening: \(error)")
            return false
        }
    }
    
    func stopListening() {
        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest = nil
        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
        
        isListening = false
        accumulatedTranscript = ""
        latestTranscript = ""
        print("🎤 Stopped live audio listening")
    }
    
    private func startRecognition() throws {
        // Cancel any existing task
        recognitionTask?.cancel()
        recognitionTask = nil
        
        // Create audio engine
        audioEngine = AVAudioEngine()
        guard let audioEngine = audioEngine else { return }
        
        let inputNode = audioEngine.inputNode
        
        // Create recognition request
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            throw NSError(domain: "LiveAudioCapture", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unable to create recognition request"])
        }
        
        recognitionRequest.shouldReportPartialResults = true
        
        // Start recognition task
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }
            
            if let result = result {
                let transcript = result.bestTranscription.formattedString
                
                DispatchQueue.main.async {
                    self.latestTranscript = transcript
                    
                    // If result is final, add to accumulated transcript
                    if result.isFinal {
                        self.accumulatedTranscript += " " + transcript
                        print("📝 Transcript: \(transcript)")
                    }
                }
            }
            
            if error != nil {
                self.stopListening()
            }
        }
        
        // Configure audio format
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            recognitionRequest.append(buffer)
        }
        
        audioEngine.prepare()
        try audioEngine.start()
    }
}
