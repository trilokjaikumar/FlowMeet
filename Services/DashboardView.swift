//
//  DashboardView.swift
//  FlowMeet
//
//  SwiftUI view that embeds the React dashboard via WKWebView
//

import SwiftUI
import WebKit

struct DashboardView: View {
    @EnvironmentObject var meetingListViewModel: MeetingListViewModel
    @EnvironmentObject var settingsViewModel: SettingsViewModel
    
    @StateObject private var bridge = WebBridge()
    @State private var isServerRunning = false
    @State private var isCheckingServer = false
    
    let dashboardURL = URL(string: "http://localhost:3000")!
    
    var body: some View {
        VStack(spacing: 0) {
            if isServerRunning {
                // Dashboard loaded successfully
                DashboardWebView(bridge: bridge)
                    .onAppear {
                        setupBridge()
                    }
                
                // Connection indicator
                if bridge.isConnected {
                    connectionIndicator
                }
            } else {
                // Server not running - show error state
                serverNotRunningView
            }
        }
        .onAppear {
            checkServerStatus()
        }
    }
    
    // MARK: - Views
    
    private var serverNotRunningView: some View {
        VStack(spacing: 24) {
            Image(systemName: "network.slash")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            VStack(spacing: 8) {
                Text("Dashboard Server Not Running")
                    .font(.title2)
                    .bold()
                
                Text("Start the React development server to view the dashboard")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            VStack(alignment: .leading, spacing: 12) {
                Text("To start the server:")
                    .font(.headline)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("1. Open Terminal")
                    Text("2. Navigate to: dashboard/")
                    Text("3. Run: npm install")
                    Text("4. Run: npm run dev")
                }
                .font(.system(.body, design: .monospaced))
                .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
            
            Button(action: {
                checkServerStatus()
            }) {
                HStack {
                    if isCheckingServer {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                    Text(isCheckingServer ? "Checking..." : "Retry Connection")
                }
                .frame(width: 200)
            }
            .buttonStyle(.borderedProminent)
            .disabled(isCheckingServer)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(40)
    }
    
    private var connectionIndicator: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(Color.green)
                .frame(width: 8, height: 8)
            
            Text("Dashboard Connected")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.green.opacity(0.1))
        .cornerRadius(12)
        .padding(8)
    }
    
    // MARK: - Functions
    
    private func checkServerStatus() {
        isCheckingServer = true
        
        var request = URLRequest(url: dashboardURL)
        request.httpMethod = "HEAD"
        request.timeoutInterval = 2
        
        URLSession.shared.dataTask(with: request) { _, response, error in
            DispatchQueue.main.async {
                isCheckingServer = false
                
                if let httpResponse = response as? HTTPURLResponse,
                   httpResponse.statusCode == 200 {
                    isServerRunning = true
                    print("✅ Dashboard server is running")
                } else {
                    isServerRunning = false
                    print("❌ Dashboard server not running:", error?.localizedDescription ?? "Unknown error")
                }
            }
        }.resume()
    }
    
    private func setupBridge() {
        // Guard against duplicate setup
        guard bridge.notificationObservers.isEmpty else { return }

        // Send initial data to dashboard
        bridge.sendSettings(settingsViewModel.settings)
        bridge.sendMeetings(meetingListViewModel.meetings)
        bridge.sendCalendarStatus(
            appleGranted: settingsViewModel.settings.appleCalendarEnabled,
            googleConnected: settingsViewModel.settings.googleCalendarEnabled
        )

        // Set up observers to send updates
        let obs1 = NotificationCenter.default.addObserver(
            forName: .settingsDidChange,
            object: nil,
            queue: .main
        ) { [bridge, settingsViewModel] _ in
            bridge.sendSettings(settingsViewModel.settings)
        }

        let obs2 = NotificationCenter.default.addObserver(
            forName: .meetingsDidUpdate,
            object: nil,
            queue: .main
        ) { [bridge] notification in
            if let meetings = notification.object as? [Meeting] {
                bridge.sendMeetings(meetings)
            }
        }

        // Handle settings updates from dashboard
        let obs3 = NotificationCenter.default.addObserver(
            forName: .settingsUpdatedFromDashboard,
            object: nil,
            queue: .main
        ) { notification in
            if let payload = notification.object as? [String: Any] {
                updateSettingsFromDashboard(payload)
            }
        }

        // Handle join meeting from dashboard
        let obs4 = NotificationCenter.default.addObserver(
            forName: .joinMeetingFromDashboard,
            object: nil,
            queue: .main
        ) { [meetingListViewModel] notification in
            if let meetingId = notification.object as? String,
               let meeting = meetingListViewModel.meetings.first(where: { $0.id.uuidString == meetingId }) {
                _ = ZoomService.shared.joinMeeting(meeting)
            }
        }

        // Handle sync calendar from dashboard
        let obs5 = NotificationCenter.default.addObserver(
            forName: .syncCalendarFromDashboard,
            object: nil,
            queue: .main
        ) { [meetingListViewModel, settingsViewModel] _ in
            Task {
                await meetingListViewModel.syncCalendars(settings: settingsViewModel.settings)
            }
        }

        // Handle add meeting from dashboard
        let obs6 = NotificationCenter.default.addObserver(
            forName: .addMeetingFromDashboard,
            object: nil,
            queue: .main
        ) { [meetingListViewModel, settingsViewModel] notification in
            if let payload = notification.object as? [String: Any],
               let title = payload["title"] as? String {
                let startDateStr = payload["startDate"] as? String
                let duration = payload["duration"] as? Double ?? 3600
                let zoomUrl = payload["zoomUrl"] as? String
                let modeStr = payload["mode"] as? String

                let startDate: Date
                if let str = startDateStr {
                    let formatter = ISO8601DateFormatter()
                    startDate = formatter.date(from: str) ?? Date()
                } else {
                    startDate = Date()
                }

                let mode = MeetingMode(rawValue: modeStr ?? "") ?? settingsViewModel.settings.defaultMode

                let meeting = Meeting(
                    title: title,
                    startDate: startDate,
                    duration: duration,
                    zoomUrl: zoomUrl,
                    source: .manual,
                    mode: mode
                )
                meetingListViewModel.addMeeting(meeting)
            }
        }

        // Handle calendar permission request from dashboard
        let obs7 = NotificationCenter.default.addObserver(
            forName: .requestCalendarPermissionFromDashboard,
            object: nil,
            queue: .main
        ) { [meetingListViewModel, bridge, settingsViewModel] _ in
            Task {
                await meetingListViewModel.requestPermissions()
                // Send the permission result back to React
                let appleGranted = settingsViewModel.settings.appleCalendarEnabled
                let googleConnected = settingsViewModel.settings.googleCalendarEnabled
                bridge.sendCalendarStatus(appleGranted: appleGranted, googleConnected: googleConnected)
            }
        }

        bridge.notificationObservers = [obs1, obs2, obs3, obs4, obs5, obs6, obs7]

        // Check connection periodically
        bridge.connectionTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
            if isServerRunning {
                bridge.checkConnection()
            }
        }
    }
    
    private func updateSettingsFromDashboard(_ payload: [String: Any]) {
        print("🔄 Updating settings from dashboard:", payload)

        // Update individual settings
        if let autoJoinEnabled = payload["autoJoinEnabled"] as? Bool {
            if autoJoinEnabled && settingsViewModel.settings.joinOffsetMinutes == 0 {
                settingsViewModel.settings.joinOffsetMinutes = 2
            } else if !autoJoinEnabled {
                settingsViewModel.settings.joinOffsetMinutes = 0
            }
        }

        if let joinLeadTime = payload["joinLeadTimeMinutes"] as? Int {
            settingsViewModel.settings.joinOffsetMinutes = joinLeadTime
        }

        if let aiEnabled = payload["aiEnabled"] as? Bool {
            settingsViewModel.settings.incognitoEnabled = !aiEnabled
        }

        if let modeString = payload["defaultMode"] as? String,
           let mode = MeetingMode(rawValue: modeString) {
            settingsViewModel.settings.defaultMode = mode
        }

        if let appleCalendarEnabled = payload["appleCalendarEnabled"] as? Bool {
            settingsViewModel.settings.appleCalendarEnabled = appleCalendarEnabled
        }

        if let googleCalendarEnabled = payload["googleCalendarEnabled"] as? Bool {
            settingsViewModel.settings.googleCalendarEnabled = googleCalendarEnabled
        }

        // Save settings
        settingsViewModel.saveSettings()

        print("✅ Settings updated and saved")
    }
}

// MARK: - DashboardWebView

struct DashboardWebView: NSViewRepresentable {
    @ObservedObject var bridge: WebBridge
    
    func makeNSView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        
        // Add message handler for React → Swift communication
        config.userContentController.add(bridge, name: "flowmeet")
        
        // Enable developer extras for debugging
        config.preferences.setValue(true, forKey: "developerExtrasEnabled")
        
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        
        // Make background transparent
        webView.setValue(false, forKey: "drawsBackground")
        
        // Connect bridge to webView
        bridge.webView = webView
        
        // Load dashboard URL
        let request = URLRequest(url: URL(string: "http://localhost:3000")!)
        webView.load(request)
        
        return webView
    }
    
    func updateNSView(_ nsView: WKWebView, context: Context) {
        // No updates needed
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: DashboardWebView
        
        init(_ parent: DashboardWebView) {
            self.parent = parent
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            print("✅ Dashboard loaded successfully")
            
            // Check connection after page loads
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.parent.bridge.checkConnection()
            }
        }
        
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            print("❌ Dashboard failed to load:", error.localizedDescription)
            parent.bridge.lastError = error.localizedDescription
        }
        
        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            print("❌ Dashboard failed provisional navigation:", error.localizedDescription)
            parent.bridge.lastError = error.localizedDescription
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let settingsDidChange = Notification.Name("settingsDidChange")
    static let meetingsDidUpdate = Notification.Name("meetingsDidUpdate")
}
