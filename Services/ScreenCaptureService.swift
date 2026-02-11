//  ScreenCaptureService.swift
//  ZoomAutoJoiner
//
//  Created by Trilokeshwar Jaikumar on 11/22/25.
//

import Foundation
import AppKit
import Vision
import Combine
import ScreenCaptureKit

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
        
        // Capture screenshot using ScreenCaptureKit
        Task {
            do {
                let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
                
                // Find the display matching our displayID
                guard let display = content.displays.first(where: { $0.displayID == displayID }) else {
                    print("Failed to find display")
                    return
                }
                
                let filter = SCContentFilter(display: display, excludingWindows: [])
                let configuration = SCStreamConfiguration()
                configuration.width = Int(screen.frame.width)
                configuration.height = Int(screen.frame.height)
                
                let capturedImage = try await SCScreenshotManager.captureImage(contentFilter: filter, configuration: configuration)
                
                // Perform OCR on background thread, update UI on main thread
                self.performOCR(on: capturedImage)
            } catch {
                print("Failed to capture screen: \(error)")
            }
        }
    }
    
    private func performOCR(on cgImage: CGImage) {
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
