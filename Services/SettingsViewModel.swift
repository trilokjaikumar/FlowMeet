//
//  SettingsViewModel.swift
//  FlowMeet
//
//  Updated to post notifications when settings change
//

import Foundation
import Combine

@MainActor
class SettingsViewModel: ObservableObject {
    @Published var settings: AppSettings {
        didSet {
            // Post notification when settings change (for dashboard)
            NotificationCenter.default.post(
                name: .settingsDidChange,
                object: settings
            )
        }
    }
    
    @Published var tempOpenAIKey: String = ""
    @Published var showIncognitoWarning = false
    
    private let defaults = UserDefaults.standard
    private let settingsKey = "appSettings"
    
    init() {
        self.settings = Self.loadSettings()
        self.tempOpenAIKey = KeychainManager.shared.load(key: "openai_api_key") ?? ""
    }
    
    static func loadSettings() -> AppSettings {
        let defaults = UserDefaults.standard
        
        if let data = defaults.data(forKey: "appSettings"),
           let decoded = try? JSONDecoder().decode(AppSettings.self, from: data) {
            return decoded
        }
        
        return AppSettings()
    }
    
    func saveSettings() {
        if let encoded = try? JSONEncoder().encode(settings) {
            defaults.set(encoded, forKey: settingsKey)
        }
        
        // Save OpenAI key to keychain if changed
        if !tempOpenAIKey.isEmpty {
            _ = KeychainManager.shared.save(key: "openai_api_key", value: tempOpenAIKey)
        }
        
        print("✅ Settings saved")
    }
    
    func toggleIncognito(_ enabled: Bool) {
        if enabled && !settings.incognitoEnabled {
            showIncognitoWarning = true
        } else {
            settings.incognitoEnabled = enabled
            saveSettings()
        }
    }
    
    func acknowledgeIncognitoWarning() {
        settings.incognitoEnabled = true
        saveSettings()
    }
    
    func testOpenAIConnection() async -> Bool {
        guard !tempOpenAIKey.isEmpty else { return false }
        
        // Simple test: try to make a minimal API call
        var request = URLRequest(url: URL(string: "https://api.openai.com/v1/models")!)
        request.setValue("Bearer \(tempOpenAIKey)", forHTTPHeaderField: "Authorization")
        
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse {
                return httpResponse.statusCode == 200
            }
        } catch {
            print("❌ OpenAI connection test failed:", error)
        }
        
        return false
    }
}
