//
//  PowerController.swift
//  PulsarX2macOS
//
//  Created by Svetlana Sibiryakova on 18.04.2025
//

import Foundation
import Combine

/// Spezialisierter Controller für die Verwaltung der Energiesparoptionen
class PowerController {
    /// Shared Instance für den Singleton-Zugriff
    static let shared = PowerController()
    
    /// USBDeviceManager für die Kommunikation mit der Maus
    private let usbManager = USBDeviceManager.shared
    
    /// ProfileManager für die Profilspeicherung
    private let profileManager = ProfileManager.shared
    
    /// Aktueller Batteriestatus in Prozent (0-100)
    private(set) var batteryLevel: Int {
        get { return usbManager.batteryLevel }
        set { /* Nur von USBDeviceManager aktualisierbar */ }
    }
    
    /// Ob die Maus im kabellosen Modus betrieben wird
    private(set) var isWireless: Bool {
        get { return usbManager.isWireless }
        set { /* Nur von USBDeviceManager aktualisierbar */ }
    }
    
    /// Publisher für Batteriestand-Aktualisierungen
    private var batteryLevelPublisher: AnyPublisher<Int, Never> {
        // In einer echten Implementierung würde dies auf einen Publisher des USBDeviceManager verweisen
        // Für dieses Beispiel wird ein einfacher Publisher simuliert
        return Just(batteryLevel).eraseToAnyPublisher()
    }
    
    /// Setzt die Energiesparoptionen
    /// - Parameters:
    ///   - idleTime: Zeit in Sekunden, bevor die Maus in den Ruhemodus wechselt (30-900)
    ///   - batteryThreshold: Optional, Prozentwert für den Low-Battery-Modus (5-20)
    /// - Returns: True bei Erfolg, sonst False
    @discardableResult
    func setPowerSaving(idleTime: Int, batteryThreshold: Int? = nil) -> Bool {
        // Gültigkeit der Zeit prüfen
        guard Settings.idleTimeRange.contains(idleTime) else {
            let validRange = Settings.idleTimeRange
            Logger.error("Ungültige Idle-Zeit: \(idleTime)s. Gültige Werte sind \(validRange.lowerBound)-\(validRange.upperBound)s.")
            
            // Auf gültigen Bereich beschränken
            let correctedTime = max(validRange.lowerBound, min(validRange.upperBound, idleTime))
            Logger.warning("Verwende korrigierte Idle-Zeit: \(correctedTime)s")
            return setPowerSaving(idleTime: correctedTime, batteryThreshold: batteryThreshold)
        }
        
        // Gültigkeit des Schwellwerts prüfen, falls angegeben
        if let threshold = batteryThreshold {
            guard Settings.batteryThresholdRange.contains(threshold) else {
                let validRange = Settings.batteryThresholdRange
                Logger.error("Ungültiger Batterieschwellwert: \(threshold)%. Gültige Werte sind \(validRange.lowerBound)-\(validRange.upperBound)%.")
                
                // Auf gültigen Bereich beschränken
                let correctedThreshold = max(validRange.lowerBound, min(validRange.upperBound, threshold))
                Logger.warning("Verwende korrigierten Batterieschwellwert: \(correctedThreshold)%")
                return setPowerSaving(idleTime: idleTime, batteryThreshold: correctedThreshold)
            }
        }
        
        // Energiesparoptionen an die Maus senden
        if !usbManager.setPowerSaving(idleTime: idleTime, batteryThreshold: batteryThreshold) {
            Logger.error("Fehler beim Setzen der Energiesparoptionen")
            return false
        }
        
        // Energiesparoptionen im Profil speichern
        var powerSaving = profileManager.activeProfile.powerSaving
        powerSaving.idleTime = idleTime
        if let threshold = batteryThreshold {
            powerSaving.lowBatteryThreshold = threshold
        }
        profileManager.updateSetting(\.powerSaving, value: powerSaving)
        
        Logger.info("Energiesparoptionen aktualisiert: Idle-Zeit = \(idleTime)s" + (batteryThreshold != nil ? ", Batterieschwellwert = \(batteryThreshold!)%" : ""))
        return true
    }
    
    /// Liefert die aktuellen Energiesparoptionen
    /// - Returns: PowerSaving-Objekt
    func getPowerSavingSettings() -> PowerSaving {
        return profileManager.activeProfile.powerSaving
    }
    
    /// Formatiert den Batteriestatus als lesbaren Text
    /// - Returns: String mit dem formatierten Batteriestatus
    func getBatteryStatusText() -> String {
        guard isWireless else {
            return "Kabelgebunden"
        }
        
        let level = batteryLevel
        if level > 75 {
            return "Ausgezeichnet (\(level)%)"
        } else if level > 50 {
            return "Gut (\(level)%)"
        } else if level > 25 {
            return "Mittel (\(level)%)"
        } else if level > 10 {
            return "Niedrig (\(level)%)"
        } else {
            return "Kritisch (\(level)%)"
        }
    }
    
    /// Liefert eine Farbe basierend auf dem Batteriestand
    /// - Returns: Name der Farbe für die Darstellung
    func getBatteryStatusColor() -> String {
        guard isWireless else {
            return "gray"
        }
        
        let level = batteryLevel
        if level > 50 {
            return "green"
        } else if level > 20 {
            return "yellow"
        } else {
            return "red"
        }
    }
    
    /// Liefert ein Batterieicon basierend auf dem Batteriestand
    /// - Returns: Name des SF-Symbols für das Batterieicon
    func getBatteryIcon() -> String {
        guard isWireless else {
            return "cable.connector"
        }
        
        let level = batteryLevel
        if level > 75 {
            return "battery.100"
        } else if level > 50 {
            return "battery.75"
        } else if level > 25 {
            return "battery.50"
        } else if level > 10 {
            return "battery.25"
        } else {
            return "battery.0"
        }
    }
    
    /// Privater Initialisierer für Singleton-Pattern
    private init() {
        // Initialisierung wird benötigt, wenn wir später weitere Eigenschaften hinzufügen
    }
}

/// Erweiterung für fortgeschrittene Batteriefunktionen
extension PowerController {
    /// Aktiviert oder deaktiviert den Niedrigenergiemodus
    /// - Parameter enabled: Ob der Niedrigenergiemodus aktiviert werden soll
    /// - Returns: True bei Erfolg, sonst False
    @discardableResult
    func setLowPowerMode(enabled: Bool) -> Bool {
        // In einer echten Implementierung würde hier ein USB-Befehl an die Maus gesendet werden
        // Da diese Funktion in unserem aktuellen Modell nicht vollständig implementiert ist,
        // verwenden wir temporäre Eigenschaften für die Dokumentation
        
        Logger.info("Niedrigenergiemodus \(enabled ? "aktiviert" : "deaktiviert")")
        return true
    }
    
    /// Berechnet die geschätzte Batterielebensdauer basierend auf den aktuellen Einstellungen
    /// - Returns: Geschätzte Lebensdauer in Stunden oder nil bei kabelgebundener Verbindung
    func estimateBatteryLife() -> Double? {
        guard isWireless else {
            return nil // Kabelgebunden
        }
        
        // In einer echten Implementierung würde hier eine komplexe Berechnung stattfinden
        // Für dieses Beispiel verwenden wir eine vereinfachte Formel
        
        let profile = profileManager.activeProfile
        
        // Basislebensdauer basierend auf dem Batteriestand
        let baseLife = Double(batteryLevel) / 100.0 * 80.0 // Maximale Lebensdauer von 80 Stunden
        
        // Faktoren für die Berechnung
        let pollingFactor = getPollingRateFactor(profile.pollingRate)
        let motionSyncFactor = profile.motionSync ? 0.85 : 1.0 // Motion Sync reduziert die Lebensdauer um 15%
        
        // Geschätzte Lebensdauer berechnen
        let estimatedLife = baseLife * pollingFactor * motionSyncFactor
        
        return max(0.5, estimatedLife) // Mindestens 30 Minuten
    }
    
    /// Berechnet den Einfluss der Polling-Rate auf die Batterielebensdauer
    /// - Parameter rate: Polling-Rate in Hz
    /// - Returns: Faktor für die Berechnung der Lebensdauer
    private func getPollingRateFactor(_ rate: Int) -> Double {
        switch rate {
        case 125:
            return 1.2  // Längere Lebensdauer bei niedriger Rate
        case 250:
            return 1.1
        case 500:
            return 1.0
        case 1000:
            return 0.85
        case 2000:
            return 0.7
        case 4000:
            return 0.6
        case 8000:
            return 0.5  // Kürzere Lebensdauer bei hoher Rate
        default:
            return 1.0
        }
    }
    
    /// Berechnet die verbleibende Zeit bis zur nächsten Ladung
    /// - Returns: Geschätzte Zeit in Stunden oder nil bei kabelgebundener Verbindung
    func estimateTimeRemaining() -> Double? {
        return estimateBatteryLife()
    }
    
    /// Berechnet die verbleibende Zeit zur vollen Ladung
    /// - Returns: Geschätzte Zeit in Minuten oder nil, wenn nicht ladend oder voll geladen
    func estimateChargingTimeRemaining() -> Int? {
        // In einer echten Implementierung würde hier der Ladestatus abgefragt werden
        // Für dieses Beispiel simulieren wir den Ladestatus
        let isCharging = false
        
        guard isCharging && batteryLevel < 100 else {
            return nil
        }
        
        // Vereinfachte Berechnung der verbleibenden Ladezeit
        let remainingPercent = 100 - batteryLevel
        let timePerPercent = 1.2 // Minuten pro Prozent
        
        return Int(Double(remainingPercent) * timePerPercent)
    }
    
    /// Aktiviert den Eco-Modus für maximale Batterielebensdauer
    /// - Returns: True bei Erfolg, sonst False
    @discardableResult
    func activateEcoMode() -> Bool {
        guard isWireless else {
            Logger.warning("Eco-Modus kann nur im kabellosen Betrieb aktiviert werden")
            return false
        }
        
        // Energiesparende Einstellungen
        let eco = setPowerSaving(idleTime: 30, batteryThreshold: 15)
        let polling = PollingController.shared.setPollingRate(rate: 125)
        let dpi = DPIController.shared.setDPI(dpi: 800)
        let motion = PerformanceController.shared.setMotionSync(enabled: false)
        
        let success = eco && polling && dpi && motion
        if success {
            Logger.info("Eco-Modus aktiviert")
        } else {
            Logger.error("Fehler beim Aktivieren des Eco-Modus")
        }
        
        return success
    }
    
    /// Aktiviert den Performance-Modus für maximale Leistung
    /// - Returns: True bei Erfolg, sonst False
    @discardableResult
    func activatePerformanceMode() -> Bool {
        // Leistungsoptimierte Einstellungen
        let power = setPowerSaving(idleTime: 300, batteryThreshold: 5)
        let polling = PollingController.shared.setPollingRate(rate: 1000)
        let dpi = DPIController.shared.setDPI(dpi: 1600)
        let motion = PerformanceController.shared.setMotionSync(enabled: true)
        
        let success = power && polling && dpi && motion
        if success {
            Logger.info("Performance-Modus aktiviert")
        } else {
            Logger.error("Fehler beim Aktivieren des Performance-Modus")
        }
        
        return success
    }
}
