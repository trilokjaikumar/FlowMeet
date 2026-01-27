//
//  ScreenCaptureService.swift
//  ZoomAutoJoiner
//
//  Created by Trilokeshwar Jaikumar on 11/22/25.
//

import Foundation
import AppKit
import Vision
import Combine

class ScreenCaptureService: NSObject, ObservableObject {
    @Published var isCapturing = false
    @Published var latestScreenText = ""
    
    private var captureTimer: Timer?
    private var captureInterval: TimeInterval = 5.0 // Capture every 5 seconds
    
    func startCapturing() {
        guard !isCapturing else { return }
        
        isCapturing = true
        print("🖥️ Starting screen capture...")
        
        // Capture immediately
        captureScreen()
        
        // Then capture periodically
        captureTimer = Timer.scheduledTimer(withTimeInterval: captureInterval, repeats: true) { [weak self] _ in
            self?.captureScreen()
        }
    }
    
    func stopCapturing() {
        captureTimer?.invalidate()
        captureTimer = nil
        isCapturing = false
        latestScreenText = ""
        print("🖥️ Stopped screen capture")
    }
    
    private func captureScreen() {
        // Get main display
        guard let screen = NSScreen.main else { return }
        let displayID = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID ?? 0
        
        // Capture screenshot
        guard let image = CGDisplayCreateImage(displayID) else {
            print("Failed to capture screen")
            return
        }
        
        // Convert to NSImage for processing
        let nsImage = NSImage(cgImage: image, size: NSSize(width: image.width, height: image.height))
        
        // Perform OCR
        performOCR(on: nsImage)
    }
    
    private func performOCR(on image: NSImage) {
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            return
        }
        
        let request = VNRecognizeTextRequest { [weak self] request, error in
            guard let observations = request.results as? [VNRecognizedTextObservation] else {
                return
            }
            
            let recognizedText = observations.compactMap { observation in
                observation.topCandidates(1).first?.string
            }.joined(separator: " ")
            
            DispatchQueue.main.async {
                // Only update if text changed significantly
                if recognizedText.count > 50 && recognizedText != self?.latestScreenText {
                    self?.latestScreenText = recognizedText
                    print("📄 Screen text updated: \(recognizedText.prefix(100))...")
                }
            }
        }
        
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        try? handler.perform([request])
    }
}
