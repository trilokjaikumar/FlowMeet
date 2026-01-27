//
//  SettingsViewModel.swift
//  ZoomAutoJoiner
//
//  Created by Trilokeshwar Jaikumar on 11/21/25.
//

import Foundation
import Combine

@MainActor
class SettingsViewModel: ObservableObject {
    @Published var settings: AppSettings
    @Published var showIncognitoWarning = false
    @Published var tempOpenAIKey: String = ""
    
    private let persistenceService = PersistenceService.shared
    private let keychainManager = KeychainManager.shared
    
    init() {
        self.settings = persistenceService.loadSettings()
        self.tempOpenAIKey = keychainManager.load(key: "openai_api_key") ?? ""
    }
    
    func saveSettings() {
        persistenceService.saveSettings(settings)
        
        // Save OpenAI key to keychain
        if !tempOpenAIKey.isEmpty {
            _ = keychainManager.save(key: "openai_api_key", value: tempOpenAIKey)
        }
    }
    
    func toggleIncognito(_ enabled: Bool) {
        if enabled && !settings.incognitoAcknowledged {
            showIncognitoWarning = true
        } else {
            settings.incognitoEnabled = enabled
            saveSettings()
        }
    }
    
    func acknowledgeIncognitoWarning() {
        settings.incognitoEnabled = true
        settings.incognitoAcknowledged = true
        showIncognitoWarning = false
        saveSettings()
    }
    
    func testOpenAIConnection() async -> Bool {
        guard !tempOpenAIKey.isEmpty else { return false }
        
        // Simple test: try to list models (placeholder)
        // In production, make a lightweight API call
        return true
    }
}
