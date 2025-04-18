//
//  MouseProfile.swift
//  PulsarX2macOS
//
//  Created by Svetlana Sibiryakova on 18.04.2025
//

import Foundation

/// Modell für die Tastenbelegung
struct ButtonMapping: Codable, Equatable {
    var action: String
    var code: UInt8
    
    init(action: String, code: UInt8) {
        self.action = action
        self.code = code
    }
}

/// Modell für Energiesparoptionen
struct PowerSaving: Codable, Equatable {
    /// Zeit in Sekunden, bevor die Maus in den Ruhemodus wechselt
    var idleTime: Int
    
    /// Prozentwert, ab dem der Low-Power-Modus aktiviert wird
    var lowBatteryThreshold: Int
    
    init(idleTime: Int = Settings.defaultIdleTime, 
         lowBatteryThreshold: Int = Settings.defaultBatteryThreshold) {
        self.idleTime = max(Settings.idleTimeRange.lowerBound, 
                            min(Settings.idleTimeRange.upperBound, idleTime))
        self.lowBatteryThreshold = max(Settings.batteryThresholdRange.lowerBound, 
                                      min(Settings.batteryThresholdRange.upperBound, lowBatteryThreshold))
    }
}

/// Modell für ein Mausprofil mit allen Einstellungen
struct MouseProfile: Codable, Equatable {
    /// DPI-Stufen als Dictionary, Schlüssel ist die Stufennummer (1-6)
    var dpiStages: [Int: Int]
    
    /// Aktive DPI-Stufe (1-6)
    var activeDpiStage: Int
    
    /// Polling-Rate in Hz
    var pollingRate: Int
    
    /// Lift-Off-Distanz in mm
    var liftOffDistance: Double
    
    /// Tastenbelegungen, Schlüssel ist die Tastennummer (1-5)
    var buttons: [Int: ButtonMapping]
    
    /// Ob Motion Sync aktiviert ist
    var motionSync: Bool
    
    /// Ob Ripple Control aktiviert ist
    var rippleControl: Bool
    
    /// Ob Angle Snap aktiviert ist
    var angleSnap: Bool
    
    /// Debounce-Zeit in ms
    var debounceTime: Int
    
    /// Energiesparoptionen
    var powerSaving: PowerSaving
    
    /// Erstellt ein neues Mausprofil mit Standardwerten
    init() {
        // Standardwerte für DPI-Stufen
        var dpiStages = [Int: Int]()
        for (index, dpi) in Settings.defaultDPIStages.enumerated() {
            dpiStages[index + 1] = dpi
        }
        self.dpiStages = dpiStages
        self.activeDpiStage = 2  // Standardmäßig Stufe 2 (1600 DPI)
        
        // Standardwerte für andere Einstellungen
        self.pollingRate = 1000
        self.liftOffDistance = 1.0
        
        // Standardwerte für Tastenbelegungen
        self.buttons = [
            1: ButtonMapping(action: "Linksklick", code: 0x01),
            2: ButtonMapping(action: "Rechtsklick", code: 0x02),
            3: ButtonMapping(action: "Mittlere Taste", code: 0x03),
            4: ButtonMapping(action: "Zurück", code: 0x04),
            5: ButtonMapping(action: "Vorwärts", code: 0x05)
        ]
        
        // Performance-Optionen
        self.motionSync = true
        self.rippleControl = false
        self.angleSnap = false
        self.debounceTime = 3
        
        // Energiesparoptionen
        self.powerSaving = PowerSaving()
    }
}

/// Konfigurationsklasse, die alle Profile verwaltet
struct Configuration: Codable {
    /// Mausprofile, Schlüssel ist die Profilnummer als String
    var profiles: [String: MouseProfile]
    
    /// Aktives Profil
    var activeProfile: String
    
    /// Erstellt eine neue Konfiguration mit einem Standardprofil
    init() {
        self.profiles = ["1": MouseProfile()]
        self.activeProfile = "1"
    }
    
    /// Aktives Mausprofil
    var activeMouseProfile: MouseProfile {
        get {
            return profiles[activeProfile] ?? MouseProfile()
        }
        set {
            profiles[activeProfile] = newValue
        }
    }
}
