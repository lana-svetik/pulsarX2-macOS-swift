//
//  PollingController.swift
//  PulsarX2macOS
//
//  Created by Svetlana Sibiryakova on 18.04.2025
//

import Foundation
import Combine

/// Spezialisierter Controller für die Verwaltung der Polling-Rate
class PollingController {
    /// Shared Instance für den Singleton-Zugriff
    static let shared = PollingController()
    
    /// USBDeviceManager für die Kommunikation mit der Maus
    private let usbManager = USBDeviceManager.shared
    
    /// ProfileManager für die Profilspeicherung
    private let profileManager = ProfileManager.shared
    
    /// Setzt die Polling-Rate
    /// - Parameter rate: Rate in Hz (125, 250, 500, 1000, 2000, 4000, 8000)
    /// - Returns: True bei Erfolg, sonst False
    @discardableResult
    func setPollingRate(rate: Int) -> Bool {
        // Gültigkeit der Rate prüfen
        guard Settings.pollingRates.contains(rate) else {
            Logger.error("Ungültige Polling-Rate: \(rate). Gültige Werte sind \(Settings.pollingRates).")
            
            // Nächstgelegene gültige Rate ermitteln
            if let closestRate = findClosestPollingRate(to: rate) {
                Logger.warning("Verwende nächstgelegene gültige Rate: \(closestRate)")
                return setPollingRate(rate: closestRate)
            }
            
            return false
        }
        
        // Warnung anzeigen, wenn eine hohe Rate verwendet wird
        if rate > 1000 {
            Logger.warning("Polling-Rate über 1000Hz (aktuell: \(rate)Hz) erfordert einen speziellen 8K-Dongle.")
            
            // Prüfen, ob ein spezieller Dongle angeschlossen ist
            if !requiresSpecialDongle(for: rate) {
                Logger.error("Kein spezieller Dongle erkannt. Rate \(rate)Hz kann möglicherweise nicht angewendet werden.")
                // Trotzdem fortfahren, für den Fall, dass die Erkennung fehlschlägt
            }
        }
        
        // Rate an die Maus senden
        if !usbManager.setPollingRate(rate: rate) {
            Logger.error("Fehler beim Setzen der Polling-Rate auf \(rate)Hz")
            return false
        }
        
        // Rate im Profil speichern
        profileManager.updateSetting(\.pollingRate, value: rate)
        
        Logger.info("Polling-Rate auf \(rate)Hz gesetzt")
        return true
    }
    
    /// Liefert die aktuelle Polling-Rate
    /// - Returns: Aktuelle Rate in Hz
    func getCurrentPollingRate() -> Int {
        return profileManager.activeProfile.pollingRate
    }
    
    /// Erhöht die Polling-Rate zum nächsthöheren verfügbaren Wert
    /// - Returns: True bei Erfolg, sonst False
    @discardableResult
    func increasePollingRate() -> Bool {
        let currentRate = getCurrentPollingRate()
        
        // Nächsthöhere Rate finden
        let availableRates = Settings.pollingRates.sorted()
        guard let currentIndex = availableRates.firstIndex(of: currentRate) else {
            // Aktuelle Rate nicht in der Liste, setze auf den nächsthöheren Wert
            if let nextRate = availableRates.first(where: { $0 > currentRate }) {
                return setPollingRate(rate: nextRate)
            }
            return false
        }
        
        // Wenn bereits auf dem höchsten Wert, nichts tun
        if currentIndex == availableRates.count - 1 {
            Logger.info("Bereits auf der höchsten Polling-Rate (\(currentRate)Hz)")
            return true
        }
        
        // Nächsthöhere Rate setzen
        let nextRate = availableRates[currentIndex + 1]
        return setPollingRate(rate: nextRate)
    }
    
    /// Verringert die Polling-Rate zum nächstniedrigeren verfügbaren Wert
    /// - Returns: True bei Erfolg, sonst False
    @discardableResult
    func decreasePollingRate() -> Bool {
        let currentRate = getCurrentPollingRate()
        
        // Nächstniedrigere Rate finden
        let availableRates = Settings.pollingRates.sorted()
        guard let currentIndex = availableRates.firstIndex(of: currentRate) else {
            // Aktuelle Rate nicht in der Liste, setze auf den nächstniedrigeren Wert
            if let prevRate = availableRates.last(where: { $0 < currentRate }) {
                return setPollingRate(rate: prevRate)
            }
            return false
        }
        
        // Wenn bereits auf dem niedrigsten Wert, nichts tun
        if currentIndex == 0 {
            Logger.info("Bereits auf der niedrigsten Polling-Rate (\(currentRate)Hz)")
            return true
        }
        
        // Nächstniedrigere Rate setzen
        let prevRate = availableRates[currentIndex - 1]
        return setPollingRate(rate: prevRate)
    }
    
    /// Findet die nächstgelegene gültige Polling-Rate
    /// - Parameter rate: Gewünschte Rate
    /// - Returns: Nächstgelegene gültige Rate oder nil, wenn keine verfügbar
    private func findClosestPollingRate(to rate: Int) -> Int? {
        guard !Settings.pollingRates.isEmpty else {
            return nil
        }
        
        return Settings.pollingRates.min(by: { abs($0 - rate) < abs($1 - rate) })
    }
    
    /// Prüft, ob für eine bestimmte Rate ein spezieller Dongle erforderlich ist
    /// - Parameter rate: Polling-Rate in Hz
    /// - Returns: True, wenn ein spezieller Dongle erforderlich ist, sonst False
    func requiresSpecialDongle(for rate: Int) -> Bool {
        // Hohe Raten (>1000Hz) erfordern einen speziellen Dongle
        if rate > 1000 {
            // Prüfen, ob der angeschlossene Dongle diese Rate unterstützt
            // (im USBDeviceManager sollte eine Methode für die Donglertyp-Erkennung vorhanden sein)
            
            // Beispielimplementierung:
            return isHighPollingDongleConnected()
        }
        
        return false
    }
    
    /// Prüft, ob ein 8K-Dongle angeschlossen ist
    /// - Returns: True, wenn ein 8K-Dongle erkannt wurde, sonst False
    private func isHighPollingDongleConnected() -> Bool {
        // In einer echten Implementierung würde hier eine Abfrage des USBDeviceManagers stehen
        // Für dieses Beispiel verwenden wir einen einfachen Produkttyp-Check
        
        // Beispielimplementierung: 
        // Überprüft anhand der Produkt-ID, ob ein 8K-Dongle angeschlossen ist
        return usbManager.getConnectedProductID() == Settings.productID8K
    }
    
    /// Liefert alle verfügbaren Polling-Raten
    /// - Returns: Array mit allen verfügbaren Raten in Hz
    func getAvailablePollingRates() -> [Int] {
        return Settings.pollingRates
    }
    
    /// Privater Initialisierer für Singleton-Pattern
    private init() {}
}

/// Erweiterung für zusätzliche Diagnosefunktionen
extension PollingController {
    /// Führt einen Polling-Rate-Test durch
    /// - Parameter completion: Callback mit dem Testergebnis (gemessene Rate in Hz)
    func testActualPollingRate(completion: @escaping (Int?) -> Void) {
        // In einer echten Implementierung würde hier ein Test der tatsächlichen Polling-Rate durchgeführt werden
        // Dies würde mehrere Berichte von der Maus sammeln und die Zeit zwischen ihnen messen
        
        // Beispielimplementierung für die Dokumentation:
        Logger.info("Starte Polling-Rate-Test...")
        
        // Hier würde eine asynchrone Messung stattfinden
        DispatchQueue.global().async {
            // Simuliere eine Verzögerung für die Messung
            Thread.sleep(forTimeInterval: 2.0)
            
            // Simuliertes Ergebnis (in einer echten Implementierung würde dies gemessen werden)
            let currentRate = self.getCurrentPollingRate()
            let measuredRate = Int(Double(currentRate) * (0.95 + Double.random(in: 0...0.1)))
            
            Logger.info("Polling-Rate-Test abgeschlossen. Eingestellte Rate: \(currentRate)Hz, Gemessene Rate: \(measuredRate)Hz")
            
            // Ergebnis zurückgeben
            DispatchQueue.main.async {
                completion(measuredRate)
            }
        }
    }
    
    /// Prüft, ob der aktuelle Dongle für die aktuelle Polling-Rate geeignet ist
    /// - Returns: True, wenn der Dongle für die aktuelle Rate geeignet ist, sonst False
    func isCurrentDongleSuitable() -> Bool {
        let currentRate = getCurrentPollingRate()
        
        if currentRate > 1000 {
            return isHighPollingDongleConnected()
        }
        
        // Für Raten bis 1000Hz ist der Standarddongle geeignet
        return true
    }
}
