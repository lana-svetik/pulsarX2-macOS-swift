//
//  Settings.swift
//  PulsarX2macOS
//
//  Created by Svetlana Sibiryakova on 18.04.2025
//

import Foundation

/// Konstanten und Einstellungen für Pulsar X2.
/// Enthält USB-IDs, DPI-Bereiche, Polling-Raten und weitere Konfigurationswerte.
struct Settings {
    // USB-IDs für Pulsar X2
    static let vendorID: Int = 0x3710      // Pulsar Vendor ID
    static let productID: Int = 0x5402     // Produkt ID für 1K-Dongle
    static let productID8K: Int = 0x5406   // Produkt ID für 8K-Dongle

    // Modellspezifikationen
    static let modelName = "X2"
    static let sensorModel = "XS-1 (PixArt)"
    static let maxDPI = 32000
    static let maxPollingRate = 8000  // Mit speziellem Dongle

    // Konfigurationswerte
    static let defaultDPIStages = [800, 1600, 3200, 6400, 12800, 25600]
    static let pollingRates = [125, 250, 500, 1000, 2000, 4000, 8000]
    static let liftOffDistances = [0.7, 1.0, 2.0]  // in mm
    
    // Standardpfad für Konfigurationsdateien
    static let configDir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!.appendingPathComponent("PulsarX2")
    static let configFile = configDir.appendingPathComponent("config.json")
    
    // Tastenkonfiguration
    static let buttonActions: [String: UInt8] = [
        "Linksklick": 0x01,
        "Rechtsklick": 0x02,
        "Mittlere Taste": 0x03,
        "Zurück": 0x04,
        "Vorwärts": 0x05,
        "DPI Hoch": 0x06,
        "DPI Runter": 0x07,
        "DPI Zyklus": 0x08,
        "Scrollrad Hoch": 0x09,
        "Scrollrad Runter": 0x0A,
        "Doppelklick": 0x0B,
        "Strg": 0x10,
        "Shift": 0x11,
        "Alt": 0x12,
        "Befehlstaste": 0x13,
        "Deaktiviert": 0x00
    ]
    
    // Maximal unterstützte Profile
    static let maxProfiles = 4
    
    // Anfangsdauer für Idle-Timer (in Sekunden)
    static let idleTimeRange = 30...900
    static let defaultIdleTime = 60
    
    // Batterieschwellwert-Bereich (in Prozent)
    static let batteryThresholdRange = 5...20
    static let defaultBatteryThreshold = 10
}
