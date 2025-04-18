//
//  PerformanceController.swift
//  PulsarX2macOS
//
//  Created by Svetlana Sibiryakova on 18.04.2025
//

import Foundation
import Combine

/// Spezialisierter Controller für die Verwaltung der Performance-Optionen
class PerformanceController {
    /// Shared Instance für den Singleton-Zugriff
    static let shared = PerformanceController()
    
    /// USBDeviceManager für die Kommunikation mit der Maus
    private let usbManager = USBDeviceManager.shared
    
    /// ProfileManager für die Profilspeicherung
    private let profileManager = ProfileManager.shared
    
    /// Aktiviert oder deaktiviert Motion Sync
    /// - Parameter enabled: Ob Motion Sync aktiviert werden soll
    /// - Returns: True bei Erfolg, sonst False
    @discardableResult
    func setMotionSync(enabled: Bool) -> Bool {
        if !usbManager.setMotionSync(enabled: enabled) {
            Logger.error("Fehler beim \(enabled ? "Aktivieren" : "Deaktivieren") von Motion Sync")
            return false
        }
        
        // Einstellung im Profil speichern
        profileManager.updateSetting(\.motionSync, value: enabled)
        
        Logger.info("Motion Sync \(enabled ? "aktiviert" : "deaktiviert")")
        return true
    }
    
    /// Aktiviert oder deaktiviert Ripple Control
    /// - Parameter enabled: Ob Ripple Control aktiviert werden soll
    /// - Returns: True bei Erfolg, sonst False
    @discardableResult
    func setRippleControl(enabled: Bool) -> Bool {
        // In einer echten Implementierung würde hier ein USB-Befehl an die Maus gesendet werden
        // Da diese Funktion in unserem aktuellen Modell nicht vollständig implementiert ist,
        // speichern wir die Einstellung nur im Profil
        
        // Einstellung im Profil speichern
        profileManager.updateSetting(\.rippleControl, value: enabled)
        
        Logger.info("Ripple Control \(enabled ? "aktiviert" : "deaktiviert")")
        return true
    }
    
    /// Aktiviert oder deaktiviert Angle Snap
    /// - Parameter enabled: Ob Angle Snap aktiviert werden soll
    /// - Returns: True bei Erfolg, sonst False
    @discardableResult
    func setAngleSnap(enabled: Bool) -> Bool {
        // In einer echten Implementierung würde hier ein USB-Befehl an die Maus gesendet werden
        // Da diese Funktion in unserem aktuellen Modell nicht vollständig implementiert ist,
        // speichern wir die Einstellung nur im Profil
        
        // Einstellung im Profil speichern
        profileManager.updateSetting(\.angleSnap, value: enabled)
        
        Logger.info("Angle Snap \(enabled ? "aktiviert" : "deaktiviert")")
        return true
    }
    
    /// Setzt die Debounce-Zeit
    /// - Parameter milliseconds: Debounce-Zeit in Millisekunden (0-20)
    /// - Returns: True bei Erfolg, sonst False
    @discardableResult
    func setDebounceTime(milliseconds: Int) -> Bool {
        // Gültigkeit der Zeit prüfen
        guard milliseconds >= 0 && milliseconds <= 20 else {
            Logger.error("Ungültige Debounce-Zeit: \(milliseconds)ms. Gültige Werte sind 0-20ms.")
            return false
        }
        
        // In einer echten Implementierung würde hier ein USB-Befehl an die Maus gesendet werden
        // Da diese Funktion in unserem aktuellen Modell nicht vollständig implementiert ist,
        // speichern wir die Einstellung nur im Profil
        
        // Einstellung im Profil speichern
        profileManager.updateSetting(\.debounceTime, value: milliseconds)
        
        Logger.info("Debounce-Zeit auf \(milliseconds)ms gesetzt")
        return true
    }
    
    /// Setzt den DPI-Effekt
    /// - Parameters:
    ///   - effect: Effekttyp ("Stabil", "Atmen", "OFF")
    ///   - brightness: Helligkeit (0-100)
    ///   - speed: Geschwindigkeit (0-100), nur für "Atmen"-Effekt
    /// - Returns: True bei Erfolg, sonst False
    @discardableResult
    func setDPIEffect(effect: String, brightness: Int = 50, speed: Int = 50) -> Bool {
        // Gültigkeit des Effekts prüfen
        guard ["Stabil", "Atmen", "OFF"].contains(effect) else {
            Logger.error("Ungültiger DPI-Effekt: \(effect). Gültige Werte sind 'Stabil', 'Atmen', 'OFF'.")
            return false
        }
        
        // Gültigkeit der Parameter prüfen
        guard brightness >= 0 && brightness <= 100 else {
            Logger.error("Ungültige Helligkeit: \(brightness). Gültige Werte sind 0-100.")
            return false
        }
        
        guard speed >= 0 && speed <= 100 else {
            Logger.error("Ungültige Geschwindigkeit: \(speed). Gültige Werte sind 0-100.")
            return false
        }
        
        // In einer echten Implementierung würde hier ein USB-Befehl an die Maus gesendet werden
        // Da diese Funktion in unserem aktuellen Modell nicht vollständig implementiert ist,
        // verwenden wir temporäre Eigenschaften für die Dokumentation
        
        // Status protokollieren
        if effect == "OFF" {
            Logger.info("DPI-Effekt deaktiviert")
        } else {
            Logger.info("DPI-Effekt auf '\(effect)' gesetzt (Helligkeit: \(brightness)%, Geschwindigkeit: \(speed)%)")
        }
        
        return true
    }
    
    /// Liefert alle Performance-Einstellungen
    /// - Returns: Dictionary mit Performance-Einstellungen
    func getPerformanceSettings() -> [String: Any] {
        let profile = profileManager.activeProfile
        
        return [
            "motionSync": profile.motionSync,
            "rippleControl": profile.rippleControl,
            "angleSnap": profile.angleSnap,
            "debounceTime": profile.debounceTime
        ]
    }
    
    /// Liefert den Wert einer Performance-Einstellung
    /// - Parameter setting: Name der Einstellung
    /// - Returns: Wert der Einstellung oder nil, wenn nicht gefunden
    func getPerformanceSetting(_ setting: String) -> Any? {
        let profile = profileManager.activeProfile
        
        switch setting {
        case "motionSync":
            return profile.motionSync
        case "rippleControl":
            return profile.rippleControl
        case "angleSnap":
            return profile.angleSnap
        case "debounceTime":
            return profile.debounceTime
        default:
            Logger.error("Unbekannte Performance-Einstellung: \(setting)")
            return nil
        }
    }
    
    /// Privater Initialisierer für Singleton-Pattern
    private init() {}
}

/// Erweiterung für fortgeschrittene Performance-Funktionen
extension PerformanceController {
    /// Führt eine Sensorkalibrierung durch
    /// - Parameter completion: Callback nach Abschluss der Kalibrierung
    func calibrateSensor(completion: @escaping (Bool) -> Void) {
        // In einer echten Implementierung würde hier eine Kalibrierungssequenz durchgeführt werden
        Logger.info("Starte Sensorkalibrierung...")
        
        // Hier würde eine asynchrone Kalibrierung stattfinden
        DispatchQueue.global().async {
            // Simuliere eine Verzögerung für die Kalibrierung
            Thread.sleep(forTimeInterval: 3.0)
            
            Logger.info("Sensorkalibrierung abgeschlossen")
            
            // Ergebnis zurückgeben
            DispatchQueue.main.async {
                completion(true)
            }
        }
    }
    
    /// Testet den Sensor auf Tracking-Probleme
    /// - Parameter completion: Callback mit den Testergebnissen
    func testSensorTracking(completion: @escaping ([String: Any]) -> Void) {
        // In einer echten Implementierung würde hier ein Tracking-Test durchgeführt werden
        Logger.info("Starte Sensor-Tracking-Test...")
        
        // Hier würde ein asynchroner Test stattfinden
        DispatchQueue.global().async {
            // Simuliere eine Verzögerung für den Test
            Thread.sleep(forTimeInterval: 4.0)
            
            // Simulierte Testergebnisse
            let results: [String: Any] = [
                "trackedPositions": 1000,
                "dropouts": 2,
                "accuracy": 99.8,
                "maxSpeed": 450,  // in IPS (Inch per Second)
                "quality": "Ausgezeichnet"
            ]
            
            Logger.info("Sensor-Tracking-Test abgeschlossen: \(results)")
            
            // Ergebnisse zurückgeben
            DispatchQueue.main.async {
                completion(results)
            }
        }
    }
    
    /// Optimiert die Performance-Einstellungen basierend auf dem Benutzerverhalten
    /// - Parameter usageProfile: Nutzungsprofil ("Gaming", "Office", "Graphic", "Custom")
    /// - Returns: True bei Erfolg, sonst False
    @discardableResult
    func optimizeForUsage(usageProfile: String) -> Bool {
        // Optimierungseinstellungen je nach Nutzungsprofil
        switch usageProfile {
        case "Gaming":
            // Optimale Einstellungen für Gaming
            setMotionSync(enabled: true)
            setRippleControl(enabled: false)
            setAngleSnap(enabled: false)
            setDebounceTime(milliseconds: 0)
            
            // DPI und Polling-Rate mit entsprechenden Controllern einstellen
            DPIController.shared.setDPI(dpi: 1600)
            PollingController.shared.setPollingRate(rate: 1000)
            
            Logger.info("Performance-Einstellungen für Gaming optimiert")
            return true
            
        case "Office":
            // Optimale Einstellungen für Office-Anwendungen
            setMotionSync(enabled: false)
            setRippleControl(enabled: true)
            setAngleSnap(enabled: true)
            setDebounceTime(milliseconds: 10)
            
            // DPI und Polling-Rate mit entsprechenden Controllern einstellen
            DPIController.shared.setDPI(dpi: 800)
            PollingController.shared.setPollingRate(rate: 500)
            
            Logger.info("Performance-Einstellungen für Office optimiert")
            return true
            
        case "Graphic":
            // Optimale Einstellungen für Grafikdesign
            setMotionSync(enabled: true)
            setRippleControl(enabled: true)
            setAngleSnap(enabled: false)
            setDebounceTime(milliseconds: 5)
            
            // DPI und Polling-Rate mit entsprechenden Controllern einstellen
            DPIController.shared.setDPI(dpi: 1200)
            PollingController.shared.setPollingRate(rate: 1000)
            
            Logger.info("Performance-Einstellungen für Grafikdesign optimiert")
            return true
            
        case "Custom":
            // Benutzerdefinierte Einstellungen beibehalten
            Logger.info("Benutzerdefinierte Performance-Einstellungen beibehalten")
            return true
            
        default:
            Logger.error("Unbekanntes Nutzungsprofil: \(usageProfile)")
            return false
        }
    }
}
