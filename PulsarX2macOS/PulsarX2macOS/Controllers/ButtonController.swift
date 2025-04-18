//
//  ButtonController.swift
//  PulsarX2macOS
//
//  Created by Svetlana Sibiryakova on 18.04.2025
//

import Foundation
import Combine

/// Spezialisierter Controller für die Verwaltung der Tastenbelegungen
class ButtonController {
    /// Shared Instance für den Singleton-Zugriff
    static let shared = ButtonController()
    
    /// USBDeviceManager für die Kommunikation mit der Maus
    private let usbManager = USBDeviceManager.shared
    
    /// ProfileManager für die Profilspeicherung
    private let profileManager = ProfileManager.shared
    
    /// Setzt die Aktion für eine bestimmte Taste
    /// - Parameters:
    ///   - button: Tastennummer (1-5)
    ///   - action: Name der Aktion aus Settings.buttonActions
    /// - Returns: True bei Erfolg, sonst False
    @discardableResult
    func setButtonAction(button: Int, action: String) -> Bool {
        // Gültigkeit der Taste prüfen
        guard button >= 1 && button <= 5 else {
            Logger.error("Ungültige Tastennummer: \(button). Gültige Werte sind 1-5.")
            return false
        }
        
        // Gültigkeit der Aktion prüfen
        guard let code = Settings.buttonActions[action] else {
            Logger.error("Ungültige Aktion: \(action)")
            return false
        }
        
        // Aktion an die Maus senden
        if !usbManager.setButtonMapping(button: button, action: action) {
            Logger.error("Fehler beim Setzen der Tastenbelegung für Taste \(button) auf \(action)")
            return false
        }
        
        // Aktion im Profil speichern
        profileManager.setButtonMapping(button: button, action: action)
        
        Logger.info("Taste \(button) auf \(action) gesetzt")
        return true
    }
    
    /// Liefert die aktuelle Aktion für eine bestimmte Taste
    /// - Parameter button: Tastennummer (1-5)
    /// - Returns: ButtonMapping-Objekt oder nil, wenn die Taste nicht existiert
    func getButtonMapping(forButton button: Int) -> ButtonMapping? {
        guard button >= 1 && button <= 5 else {
            Logger.error("Ungültige Tastennummer: \(button). Gültige Werte sind 1-5.")
            return nil
        }
        
        return profileManager.activeProfile.buttons[button]
    }
    
    /// Liefert alle aktuellen Tastenbelegungen
    /// - Returns: Dictionary mit Tastennummern als Schlüssel und ButtonMapping-Objekten
    func getAllButtonMappings() -> [Int: ButtonMapping] {
        return profileManager.activeProfile.buttons
    }
    
    /// Setzt alle Tastenbelegungen auf Standardwerte zurück
    /// - Returns: True bei Erfolg, sonst False
    @discardableResult
    func resetToDefaultMappings() -> Bool {
        let defaultMappings: [Int: String] = [
            1: "Linksklick",
            2: "Rechtsklick",
            3: "Mittlere Taste",
            4: "Zurück",
            5: "Vorwärts"
        ]
        
        var success = true
        
        // Jede Taste auf Standardwert setzen
        for (button, action) in defaultMappings {
            if !setButtonAction(button: button, action: action) {
                success = false
            }
        }
        
        return success
    }
    
    /// Exportiert alle Tastenbelegungen in ein JSON-Format
    /// - Returns: JSON-String mit allen Tastenbelegungen oder nil bei Fehler
    func exportButtonMappingsAsJSON() -> String? {
        let buttonMappings = getAllButtonMappings()
        
        // Vereinfachtes Format für den Export erstellen
        var exportFormat: [String: String] = [:]
        for (button, mapping) in buttonMappings {
            exportFormat[String(button)] = mapping.action
        }
        
        do {
            let jsonData = try JSONEncoder().encode(exportFormat)
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                return jsonString
            }
        } catch {
            Logger.error("Fehler beim Exportieren der Tastenbelegungen: \(error)")
        }
        
        return nil
    }
    
    /// Importiert Tastenbelegungen aus einem JSON-Format
    /// - Parameter jsonString: JSON-String mit Tastenbelegungen
    /// - Returns: True bei Erfolg, sonst False
    @discardableResult
    func importButtonMappingsFromJSON(_ jsonString: String) -> Bool {
        guard let jsonData = jsonString.data(using: .utf8) else {
            Logger.error("Ungültiges JSON-Format")
            return false
        }
        
        do {
            let importFormat = try JSONDecoder().decode([String: String].self, from: jsonData)
            
            for (buttonStr, action) in importFormat {
                if let button = Int(buttonStr), button >= 1 && button <= 5 {
                    if !setButtonAction(button: button, action: action) {
                        Logger.warning("Konnte Aktion \(action) für Taste \(button) nicht setzen")
                    }
                }
            }
            
            return true
        } catch {
            Logger.error("Fehler beim Importieren der Tastenbelegungen: \(error)")
            return false
        }
    }
    
    /// Überprüft, ob eine Aktion verfügbar ist
    /// - Parameter action: Name der Aktion
    /// - Returns: True, wenn die Aktion verfügbar ist, sonst False
    func isActionAvailable(_ action: String) -> Bool {
        return Settings.buttonActions[action] != nil
    }
    
    /// Liefert alle verfügbaren Aktionen, gruppiert nach Kategorien
    /// - Returns: Dictionary mit Kategorien als Schlüssel und Arrays von Aktionen
    func getAvailableActionsByCategory() -> [String: [String]] {
        return [
            "Maustasten": ["Linksklick", "Rechtsklick", "Mittlere Taste", "Zurück", "Vorwärts"],
            "DPI": ["DPI Hoch", "DPI Runter", "DPI Zyklus"],
            "Scrollen": ["Scrollrad Hoch", "Scrollrad Runter"],
            "Tastatur": ["Strg", "Shift", "Alt", "Befehlstaste", "Doppelklick"],
            "Sonstiges": ["Deaktiviert"]
        ]
    }
    
    /// Privater Initialisierer für Singleton-Pattern
    private init() {}
}

/// Erweiterung für das Hinzufügen von Makroaktionen zu Tasten
extension ButtonController {
    /// Weist einer Taste ein Makro zu
    /// - Parameters:
    ///   - button: Tastennummer (1-5)
    ///   - macroName: Name des Makros
    /// - Returns: True bei Erfolg, sonst False
    @discardableResult
    func assignMacroToButton(button: Int, macroName: String) -> Bool {
        // Diese Funktion würde in der tatsächlichen Implementierung
        // mit dem MacroManager zusammenarbeiten, um ein Makro einer Taste zuzuweisen.
        // Für dieses Beispiel verwenden wir eine vereinfachte Implementierung.
        
        // Simulieren der Aktion mit einer benutzerdefinierten Aktion
        let customAction = "Makro: \(macroName)"
        
        // Im Profil speichern (nicht an die Maus senden, da dies eine spezielle Behandlung erfordert)
        var profile = profileManager.activeProfile
        
        // Erstellen einer benutzerdefinierten ButtonMapping
        let mapping = ButtonMapping(action: customAction, code: 0xF0) // Spezieller Code für Makros
        profile.buttons[button] = mapping
        
        // Profil aktualisieren
        profileManager.activeProfile = profile
        
        // Eine echte Implementierung würde spezielle Befehle an die Maus senden
        // und möglicherweise eine komplexere Logik zur Makroverwaltung enthalten
        
        Logger.info("Makro '\(macroName)' der Taste \(button) zugewiesen")
        return true
    }
    
    /// Prüft, ob eine Taste mit einem Makro belegt ist
    /// - Parameter button: Tastennummer (1-5)
    /// - Returns: True, wenn die Taste ein Makro zugewiesen hat, sonst False
    func hasButtonMacro(button: Int) -> Bool {
        guard let mapping = getButtonMapping(forButton: button) else {
            return false
        }
        
        return mapping.action.starts(with: "Makro: ")
    }
    
    /// Liefert den Namen des Makros für eine Taste
    /// - Parameter button: Tastennummer (1-5)
    /// - Returns: Makroname oder nil, wenn die Taste kein Makro zugewiesen hat
    func getMacroNameForButton(button: Int) -> String? {
        guard let mapping = getButtonMapping(forButton: button),
              mapping.action.starts(with: "Makro: ") else {
            return nil
        }
        
        // Format: "Makro: MacroName"
        let components = mapping.action.split(separator: ": ", maxSplits: 1)
        if components.count > 1 {
            return String(components[1])
        }
        
        return nil
    }
}
