//
//  DPIController.swift
//  PulsarX2macOS
//
//  Created by Svetlana Sibiryakova on 18.04.2025
//

import Foundation
import Combine

/// Spezialisierter Controller für die Verwaltung der DPI-Einstellungen
class DPIController {
    /// Shared Instance für den Singleton-Zugriff
    static let shared = DPIController()
    
    /// USBDeviceManager für die Kommunikation mit der Maus
    private let usbManager = USBDeviceManager.shared
    
    /// ProfileManager für die Profilspeicherung
    private let profileManager = ProfileManager.shared
    
    /// Aktueller DPI-Wert für die aktive Stufe
    private var currentDPI: Int {
        let profile = profileManager.activeProfile
        let stage = profile.activeDpiStage
        return profile.dpiStages[stage] ?? Settings.defaultDPIStages[0]
    }
    
    /// Aktive DPI-Stufe
    private var activeDPIStage: Int {
        return profileManager.activeProfile.activeDpiStage
    }
    
    /// Anzahl der konfigurierten DPI-Stufen
    private var stageCount: Int {
        return profileManager.activeProfile.dpiStages.count
    }
    
    /// Setzt die DPI für eine bestimmte Stufe
    /// - Parameters:
    ///   - dpi: DPI-Wert (50-32000)
    ///   - stage: Stufennummer (1-6), wenn nil, wird die aktive Stufe verwendet
    /// - Returns: True bei Erfolg, sonst False
    @discardableResult
    func setDPI(dpi: Int, stage: Int? = nil) -> Bool {
        // DPI-Wert auf gültigen Bereich beschränken
        let validDPI = max(50, min(Settings.maxDPI, dpi))
        // DPI auf 10er-Schritte runden
        let roundedDPI = (validDPI / 10) * 10
        
        // Stufennummer bestimmen
        let targetStage = stage ?? activeDPIStage
        
        // Gültigkeit der Stufe prüfen
        guard targetStage >= 1 && targetStage <= 6 else {
            Logger.error("Ungültige DPI-Stufe: \(targetStage). Gültige Werte sind 1-6.")
            return false
        }
        
        // DPI-Wert an die Maus senden
        if !usbManager.setDPI(dpi: roundedDPI, stage: targetStage) {
            Logger.error("Fehler beim Setzen der DPI: \(roundedDPI) für Stufe \(targetStage)")
            return false
        }
        
        // DPI-Wert im Profil speichern
        profileManager.setDPI(dpi: roundedDPI, stage: targetStage)
        
        Logger.info("DPI für Stufe \(targetStage) auf \(roundedDPI) gesetzt")
        return true
    }
    
    /// Setzt die aktive DPI-Stufe
    /// - Parameter stage: Stufennummer (1-6)
    /// - Returns: True bei Erfolg, sonst False
    @discardableResult
    func setActiveDPIStage(stage: Int) -> Bool {
        // Gültigkeit der Stufe prüfen
        guard stage >= 1 && stage <= stageCount else {
            Logger.error("Ungültige DPI-Stufe: \(stage). Gültige Werte sind 1-\(stageCount).")
            return false
        }
        
        // Aktueller DPI-Wert für die gewählte Stufe
        guard let dpi = profileManager.activeProfile.dpiStages[stage] else {
            Logger.error("DPI-Stufe \(stage) ist nicht konfiguriert")
            return false
        }
        
        // DPI-Wert an die Maus senden
        if !usbManager.setDPI(dpi: dpi, stage: stage) {
            Logger.error("Fehler beim Aktivieren der DPI-Stufe \(stage) mit DPI \(dpi)")
            return false
        }
        
        // Aktive Stufe im Profil aktualisieren
        profileManager.setActiveDPIStage(stage: stage)
        
        Logger.info("Aktive DPI-Stufe auf \(stage) mit DPI \(dpi) gesetzt")
        return true
    }
    
    /// Wechselt zur nächsten DPI-Stufe (zyklisch)
    /// - Returns: True bei Erfolg, sonst False
    @discardableResult
    func cycleDPIStage() -> Bool {
        guard stageCount > 0 else {
            Logger.error("Keine DPI-Stufen konfiguriert")
            return false
        }
        
        // Nächste Stufe bestimmen (zyklisch)
        let nextStage = (activeDPIStage % stageCount) + 1
        
        // Zur nächsten Stufe wechseln
        return setActiveDPIStage(stage: nextStage)
    }
    
    /// Aktualisiert die Anzahl der DPI-Stufen
    /// - Parameter count: Anzahl der Stufen (1-6)
    /// - Returns: True bei Erfolg, sonst False
    @discardableResult
    func updateStageCount(_ count: Int) -> Bool {
        // Gültigkeit der Anzahl prüfen
        guard count >= 1 && count <= 6 else {
            Logger.error("Ungültige Anzahl DPI-Stufen: \(count). Gültige Werte sind 1-6.")
            return false
        }
        
        var profile = profileManager.activeProfile
        
        // Bestehende Stufen beibehalten und fehlende hinzufügen
        for stage in 1...count {
            if profile.dpiStages[stage] == nil {
                // Standardwert für neue Stufe setzen
                let defaultValue = stage <= Settings.defaultDPIStages.count
                    ? Settings.defaultDPIStages[stage - 1]
                    : 800 * Int(pow(2.0, Double(stage - 1)))
                
                profile.dpiStages[stage] = defaultValue
            }
        }
        
        // Überzählige Stufen entfernen
        for stage in count+1...6 {
            profile.dpiStages.removeValue(forKey: stage)
        }
        
        // Sicherstellen, dass die aktive Stufe gültig ist
        if profile.activeDpiStage > count {
            profile.activeDpiStage = count
        }
        
        // Profil aktualisieren
        profileManager.activeProfile = profile
        
        Logger.info("Anzahl der DPI-Stufen auf \(count) gesetzt")
        return true
    }
    
    /// Liefert alle verfügbaren DPI-Stufen mit ihren Werten
    /// - Returns: Dictionary mit Stufennummern als Schlüssel und DPI-Werten
    func getAllDPIStages() -> [Int: Int] {
        return profileManager.activeProfile.dpiStages
    }
    
    /// Liefert den DPI-Wert für eine bestimmte Stufe
    /// - Parameter stage: Stufennummer (1-6), wenn nil, wird die aktive Stufe verwendet
    /// - Returns: DPI-Wert oder nil, wenn die Stufe nicht existiert
    func getDPI(forStage stage: Int? = nil) -> Int? {
        let targetStage = stage ?? activeDPIStage
        return profileManager.activeProfile.dpiStages[targetStage]
    }
    
    /// Liefert die aktive DPI-Stufe
    /// - Returns: Aktive Stufennummer
    func getActiveDPIStage() -> Int {
        return activeDPIStage
    }
    
    /// Privater Initialisierer für Singleton-Pattern
    private init() {}
}
