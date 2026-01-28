//
//  WebBridge.swift
//  FlowMeet
//
//  Bridge for communication between Swift and React Dashboard
//

import Foundation
import WebKit
import Combine

class WebBridge: NSObject, ObservableObject {
    weak var webView: WKWebView?
    
    @Published var isConnected = false
    @Published var lastError: String?
    
    // MARK: - Swift → React
    
    /// Send settings to React dashboard
    func sendSettings(_ settings: AppSettings) {
        guard let webView = webView else {
            lastError = "WebView not initialized"
            return
        }
        
        let settingsDict: [String: Any] = [
            "autoJoinEnabled": settings.joinOffsetMinutes > 0,
            "joinLeadTimeMinutes": settings.joinOffsetMinutes,
            "aiEnabled": !settings.incognitoEnabled,
            "defaultMode": settings.defaultMode.rawValue,
            "appleCalendarEnabled": settings.appleCalendarEnabled,
            "googleCalendarEnabled": settings.googleCalendarEnabled,
            "joinOffsetMinutes": settings.joinOffsetMinutes,
            "incognitoEnabled": settings.incognitoEnabled,
            "calendarSyncDays": settings.calendarSyncDays,
            "audioSource": settings.audioSource.rawValue,
            "transcriptionModel": settings.transcriptionModel,
            "notesModel": settings.notesModel
        ]
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: settingsDict),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            lastError = "Failed to serialize settings"
            return
        }
        
        let script = """
        if (window.flowmeetReceiveSettings) {
            window.flowmeetReceiveSettings(\(jsonString));
        }
        """
        
        webView.evaluateJavaScript(script) { [weak self] result, error in
            if let error = error {
                self?.lastError = "Failed to send settings: \(error.localizedDescription)"
                print("❌ Error sending settings to React: \(error)")
            } else {
                print("✅ Settings sent to React dashboard")
                self?.isConnected = true
            }
        }
    }
    
    /// Send meetings data to React dashboard
    func sendMeetings(_ meetings: [Meeting]) {
        guard let webView = webView else {
            lastError = "WebView not initialized"
            return
        }
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        
        guard let jsonData = try? encoder.encode(meetings),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            lastError = "Failed to serialize meetings"
            return
        }
        
        let script = """
        if (window.flowmeetReceiveMeetings) {
            window.flowmeetReceiveMeetings(\(jsonString));
        }
        """
        
        webView.evaluateJavaScript(script) { result, error in
            if let error = error {
                print("❌ Error sending meetings to React: \(error)")
            } else {
                print("✅ Meetings sent to React dashboard")
            }
        }
    }
    
    /// Send audio recording status to React
    func sendRecordingStatus(isRecording: Bool, level: Double = 0) {
        guard let webView = webView else { return }
        
        let script = """
        if (window.flowmeetReceiveRecordingStatus) {
            window.flowmeetReceiveRecordingStatus({
                isRecording: \(isRecording),
                level: \(level)
            });
        }
        """
        
        webView.evaluateJavaScript(script) { result, error in
            if let error = error {
                print("❌ Error sending recording status: \(error)")
            }
        }
    }
    
    // MARK: - Connectivity Check
    
    /// Check if the dashboard is loaded and ready
    func checkConnection() {
        guard let webView = webView else { return }
        
        let script = "typeof window.flowmeetReceiveSettings !== 'undefined'"
        
        webView.evaluateJavaScript(script) { [weak self] result, error in
            if let isReady = result as? Bool, isReady {
                self?.isConnected = true
                print("✅ React dashboard is connected")
            } else {
                self?.isConnected = false
                print("⚠️ React dashboard not ready yet")
            }
        }
    }
}

// MARK: - WKScriptMessageHandler (React → Swift)

extension WebBridge: WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard message.name == "flowmeet",
              let body = message.body as? [String: Any],
              let type = body["type"] as? String else {
            print("⚠️ Invalid message from React:", message.body)
            return
        }
        
        print("📨 Message from React:", type)
        
        switch type {
        case "updateSettings":
            handleUpdateSettings(body["payload"] as? [String: Any])
            
        case "joinMeeting":
            handleJoinMeeting(body["payload"] as? [String: Any])
            
        case "showMeetingDetail":
            handleShowMeetingDetail(body["payload"] as? [String: Any])
            
        case "ready":
            // Dashboard is loaded and ready
            isConnected = true
            print("✅ Dashboard ready signal received")
            
        default:
            print("⚠️ Unknown message type:", type)
        }
    }
    
    // MARK: - Message Handlers
    
    private func handleUpdateSettings(_ payload: [String: Any]?) {
        guard let payload = payload else {
            print("⚠️ No payload in updateSettings")
            return
        }
        
        print("🔄 Updating settings from React:", payload)
        
        // Post notification for SettingsViewModel to handle
        NotificationCenter.default.post(
            name: .settingsUpdatedFromDashboard,
            object: payload
        )
    }
    
    private func handleJoinMeeting(_ payload: [String: Any]?) {
        guard let payload = payload,
              let meetingId = payload["meetingId"] as? String else {
            print("⚠️ Invalid joinMeeting payload")
            return
        }
        
        print("🚀 Join meeting request:", meetingId)
        
        // Post notification for MeetingListViewModel to handle
        NotificationCenter.default.post(
            name: .joinMeetingFromDashboard,
            object: meetingId
        )
    }
    
    private func handleShowMeetingDetail(_ payload: [String: Any]?) {
        guard let payload = payload,
              let meetingId = payload["meetingId"] as? String else {
            print("⚠️ Invalid showMeetingDetail payload")
            return
        }
        
        print("📋 Show meeting detail:", meetingId)
        
        // Post notification for navigation
        NotificationCenter.default.post(
            name: .showMeetingDetailFromDashboard,
            object: meetingId
        )
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let settingsUpdatedFromDashboard = Notification.Name("settingsUpdatedFromDashboard")
    static let joinMeetingFromDashboard = Notification.Name("joinMeetingFromDashboard")
    static let showMeetingDetailFromDashboard = Notification.Name("showMeetingDetailFromDashboard")
}
