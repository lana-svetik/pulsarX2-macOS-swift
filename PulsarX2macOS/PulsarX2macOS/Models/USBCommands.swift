//
//  USBCommands.swift
//  PulsarX2macOS
//
//  Created by Svetlana Sibiryakova on 18.04.2025
//

import Foundation

/// USB-Befehle für die Kommunikation mit der Pulsar X2 Maus
struct USBCommands {
    /// Befehl zum Abrufen von Informationen über die Maus
    static let cmdGetInfo: [UInt8] = [0x10, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]
    
    /// Befehl zum Abrufen der aktuellen Einstellungen
    static let cmdGetSettings: [UInt8] = [0x12, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]
    
    /// Befehl zum Einstellen der DPI
    /// - Parameters:
    ///   - dpi: DPI-Wert (50-32000)
    ///   - stage: DPI-Stufe (1-6)
    /// - Returns: Der formatierte Befehl als Byte-Array
    static func setDPI(dpi: Int, stage: Int = 1) -> [UInt8] {
        var command: [UInt8] = [0x20, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]
        
        // DPI-Wert auf gültigen Bereich beschränken und auf 10er-Schritte runden
        let validDPI = min(Settings.maxDPI, max(50, dpi))
        let roundedDPI = (validDPI / 10) * 10
        
        command[1] = UInt8(stage)
        command[2] = UInt8((roundedDPI >> 8) & 0xFF)  // High-Byte
        command[3] = UInt8(roundedDPI & 0xFF)         // Low-Byte
        
        return command
    }
    
    /// Befehl zum Einstellen der Polling-Rate
    /// - Parameter rate: Polling-Rate in Hz (125, 250, 500, 1000, 2000, 4000, 8000)
    /// - Returns: Der formatierte Befehl als Byte-Array
    static func setPollingRate(rate: Int) -> [UInt8] {
        var command: [UInt8] = [0x30, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]
        
        // Rate zu einer der unterstützten Raten zuordnen
        let rateMapping: [Int: UInt8] = [
            125: 0,
            250: 1,
            500: 2,
            1000: 3,
            2000: 4,
            4000: 5,
            8000: 6
        ]
        
        if let rateValue = rateMapping[rate] {
            command[1] = rateValue
        }
        
        return command
    }
    
    /// Befehl zum Einstellen der Lift-Off-Distanz
    /// - Parameter distance: Distanz in mm (0.7, 1.0, 2.0)
    /// - Returns: Der formatierte Befehl als Byte-Array
    static func setLiftOffDistance(distance: Double) -> [UInt8] {
        var command: [UInt8] = [0x40, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]
        
        // Distanz zu einem der unterstützten Werte zuordnen
        let distMapping: [Double: UInt8] = [
            0.7: 0,
            1.0: 1,
            2.0: 2
        ]
        
        if let distValue = distMapping[distance] {
            command[1] = distValue
        }
        
        return command
    }
    
    /// Befehl zum Einstellen einer Tastenfunktion
    /// - Parameters:
    ///   - button: Tastennummer (1-5)
    ///   - action: Aktionscode aus Settings.buttonActions
    /// - Returns: Der formatierte Befehl als Byte-Array
    static func setButton(button: Int, action: UInt8) -> [UInt8] {
        var command: [UInt8] = [0x50, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]
        
        command[1] = UInt8(button)
        command[2] = action
        
        return command
    }
    
    /// Befehl zum Aktivieren/Deaktivieren von Motion Sync
    /// - Parameter enabled: Ob Motion Sync aktiviert werden soll
    /// - Returns: Der formatierte Befehl als Byte-Array
    static func setMotionSync(enabled: Bool) -> [UInt8] {
        var command: [UInt8] = [0x60, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]
        
        command[1] = enabled ? 1 : 0
        
        return command
    }
    
    /// Befehl zum Einstellen der Energiesparoptionen
    /// - Parameters:
    ///   - idleTime: Zeit in Sekunden, bevor die Maus in den Ruhemodus wechselt
    ///   - batteryThreshold: Optional, Prozentwert für den Low-Battery-Modus
    /// - Returns: Der formatierte Befehl als Byte-Array
    static func setPowerSaving(idleTime: Int, batteryThreshold: Int? = nil) -> [UInt8] {
        var command: [UInt8] = [0x70, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]
        
        // Idle-Zeit auf Bytes aufteilen
        command[1] = UInt8(idleTime & 0xFF)         // Low-Byte
        command[2] = UInt8((idleTime >> 8) & 0xFF)  // High-Byte
        
        if let threshold = batteryThreshold {
            command[3] = UInt8(threshold)
        }
        
        return command
    }
    
    /// Befehl zum Speichern der Einstellungen in einem Profil
    /// - Parameter profileNumber: Profilnummer (1-4)
    /// - Returns: Der formatierte Befehl als Byte-Array
    static func saveProfile(profileNumber: Int) -> [UInt8] {
        var command: [UInt8] = [0xF0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]
        
        command[1] = UInt8(profileNumber)
        
        return command
    }
}
