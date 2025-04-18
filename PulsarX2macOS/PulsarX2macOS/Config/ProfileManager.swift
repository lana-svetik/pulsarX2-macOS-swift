//
//  ProfileManager.swift
//  PulsarX2macOS
//
//  Created by Svetlana Sibiryakova on 18.04.2025
//

import Foundation
import Combine

/// Manager-Klasse für die Verwaltung der Maus-Profile und Konfigurationen
class ProfileManager {
    /// Shared Instance für den Singleton-Zugriff
    static let shared = ProfileManager()
    
    /// Aktuelle Konfiguration mit allen Profilen
    @Published private(set) var configuration: Configuration
    
    /// Publisher für Konfigurationsänderungen
    var configurationPublisher: AnyPublisher<Configuration, Never> {
        return $configuration.eraseToAnyPublisher()
    }
    
    /// Privater Initialisierer für Singleton-Pattern
    private init() {
        // Standardkonfiguration erstellen
        self.configuration = Configuration()
        
        // Konfigurationsverzeichnis prüfen/erstellen
        ensureConfigDir()
        
        // Konfiguration laden
        loadConfig()
    }
    
    /// Stellt sicher, dass das Konfigurationsverzeichnis existiert
    private func ensureConfigDir() {
        if !FileManager.default.fileExists(atPath: Settings.configDir.path) {
            do {
                try FileManager.default.createDirectory(at: Settings.configDir, 
                                                      withIntermediateDirectories: true, 
                                                      attributes: nil)
                print("Konfigurationsverzeichnis erstellt: \(Settings.configDir.path)")
            } catch {
                print("Fehler beim Erstellen des Konfigurationsverzeichnisses: \(error)")
            }
        }
    }
    
    /// Lädt die Konfiguration aus einer Datei
    func loadConfig() {
        if !FileManager.default.fileExists(atPath: Settings.configFile.path) {
            print("Keine gespeicherte Konfiguration gefunden, verwende Standardwerte.")
            saveConfig() // Standardkonfiguration speichern
            return
        }
        
        do {
            let data = try Data(contentsOf: Settings.configFile)
            let decoder = JSONDecoder()
            self.configuration = try decoder.decode(Configuration.self, from: data)
            print("Konfiguration geladen: \(Settings.configFile.path)")
        } catch {
            print("Fehler beim Laden der Konfiguration: \(error)")
            // Bei Fehler Standardkonfiguration verwenden und speichern
            self.configuration = Configuration()
            saveConfig()
        }
    }
    
    /// Speichert die aktuelle Konfiguration in eine Datei
    func saveConfig() {
        do {
            let encoder = JSONDecoder()
            let data = try encoder.encode(configuration)
            try data.write(to: Settings.configFile)
            print("Konfiguration gespeichert: \(Settings.configFile.path)")
        } catch {
            print("Fehler beim Speichern der Konfiguration: \(error)")
        }
    }
    
    /// Setzt das aktive Profil
    /// - Parameter profileId: ID des zu aktivierenden Profils
    func setActiveProfile(profileId: String) {
        if configuration.profiles[profileId] != nil {
            configuration.activeProfile = profileId
            saveConfig()
        } else {
            print("Fehler: Profil \(profileId) nicht gefunden.")
        }
    }
    
    /// Erstellt ein neues Profil
    /// - Parameters:
    ///   - profileId: ID des neuen Profils
    ///   - setActive: Ob das neue Profil aktiviert werden soll
    func createProfile(profileId: String, setActive: Bool = false) {
        configuration.profiles[profileId] = MouseProfile()
        if setActive {
            configuration.activeProfile = profileId
        }
        saveConfig()
    }
    
    /// Kopiert ein Profil
    /// - Parameters:
    ///   - sourceId: Quellprofil
    ///   - targetId: Zielprofil
    func copyProfile(sourceId: String, targetId: String) {
        guard let sourceProfile = configuration.profiles[sourceId] else {
            print("Fehler: Quellprofil \(sourceId) nicht gefunden.")
            return
        }
        
        configuration.profiles[targetId] = sourceProfile
        print("Profil \(sourceId) wurde nach Profil \(targetId) kopiert.")
        saveConfig()
    }
    
    /// Setzt ein Profil auf Standardwerte zurück
    /// - Parameter profileId: ID des zurückzusetzenden Profils
    func resetProfile(profileId: String) {
        if configuration.profiles[profileId] != nil {
            configuration.profiles[profileId] = MouseProfile()
            print("Profil \(profileId) wurde auf Standardwerte zurückgesetzt.")
            saveConfig()
        } else {
            print("Fehler: Profil \(profileId) nicht gefunden.")
        }
    }
    
    /// Löscht ein Profil
    /// - Parameter profileId: ID des zu löschenden Profils
    func deleteProfile(profileId: String) {
        // Prüfen, ob es mindestens ein Profil nach dem Löschen gibt
        if configuration.profiles.count > 1 {
            // Falls das aktive Profil gelöscht wird, ein anderes aktivieren
            if configuration.activeProfile == profileId {
                let newActiveId = configuration.profiles.keys.first(where: { $0 != profileId }) ?? "1"
                configuration.activeProfile = newActiveId
            }
            
            configuration.profiles.removeValue(forKey: profileId)
            saveConfig()
        } else {
            print("Fehler: Das letzte Profil kann nicht gelöscht werden.")
        }
    }
    
    /// Gibt das aktive Profil zurück
    var activeProfile: MouseProfile {
        get {
            return configuration.activeMouseProfile
        }
        set {
            configuration.activeMouseProfile = newValue
            saveConfig()
        }
    }
    
    /// Aktualisiert eine Einstellung im aktiven Profil
    /// - Parameters:
    ///   - keyPath: KeyPath zur Eigenschaft
    ///   - value: Neuer Wert
    func updateSetting<T>(_ keyPath: WritableKeyPath<MouseProfile, T>, value: T) {
        var profile = activeProfile
        profile[keyPath: keyPath] = value
        activeProfile = profile
    }
    
    /// Setzt die DPI für eine bestimmte Stufe
    /// - Parameters:
    ///   - dpi: DPI-Wert
    ///   - stage: Stufennummer (1-6)
    func setDPI(dpi: Int, stage: Int) {
        var profile = activeProfile
        profile.dpiStages[stage] = dpi
        activeProfile = profile
    }
    
    /// Setzt die aktive DPI-Stufe
    /// - Parameter stage: Stufennummer (1-6)
    func setActiveDPIStage(stage: Int) {
        updateSetting(\.activeDpiStage, value: stage)
    }
    
    /// Wechselt zur nächsten DPI-Stufe
    func cycleDPIStage() {
        var profile = activeProfile
        let stages = profile.dpiStages.keys.sorted()
        guard !stages.isEmpty else { return }
        
        let currentStage = profile.activeDpiStage
        let currentIndex = stages.firstIndex(of: currentStage) ?? 0
        let nextIndex = (currentIndex + 1) % stages.count
        profile.activeDpiStage = stages[nextIndex]
        
        activeProfile = profile
    }
    
    /// Aktualisiert die Tastenbelegung
    /// - Parameters:
    ///   - button: Tastennummer (1-5)
    ///   - action: Aktionsname
    func setButtonMapping(button: Int, action: String) {
        guard let code = Settings.buttonActions[action] else {
            print("Ungültige Aktion: \(action)")
            return
        }
        
        var profile = activeProfile
        profile.buttons[button] = ButtonMapping(action: action, code: code)
        activeProfile = profile
    }
}
